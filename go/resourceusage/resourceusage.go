package main

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/signal"
	"time"

	notificationv1 "github.com/EngFlow/engflowapis-go/engflow/notification/v1"
	resourceusagev1 "github.com/EngFlow/engflowapis-go/engflow/resourceusage/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/status"
)

const (
	maxRetries             = 3
	resourceUsageQueueName = "resourceusage/events"
)

const helpMessage = `usage: resourceusage -service=example.cluster.engflow.com:443 -tls_client_auth_cert=file.crt -tls_client_auth_key=file.key

resourceusage streams Resource Usage API events from an EngFlow server and
prints them to stdout as JSON.

This program is meant to serve as an example only. You'll likely want to
implement your own client to store events somewhere safe for processing.

Be careful: the server does not store events after they have been received
and acknowledged by a client. In most cases, you should store events to a file
or other persistent data store for later processing.

To use this API:

1. Check with your Customer Success contact if the Resource Usage API is
   enabled. This is a preview API, not available on most clusters. It is
   likely to change in the future.
2. Log into your EngFlow cluster. You must have the admin or global-admin
   role or the notification:Pull permission.
3. Generate, download, and extract an mTLS certificate from the
   'Getting Started' page.
4. Run this tool with a command like the one below, replacing the cluster name
   and the paths to your mTLS certificate files.

    bazel run //go/resourceusage -- \
      -service=example.cluster.engflow.com:443 \
      -tls_client_auth_cert=path/to/engflow.crt \
      -tls_client_auth_key=path/to/engflow.key | \
      tee -a events.json
`

func main() {
	// Stop when the user presses ^C
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	// Change to the user's current directory if run by 'bazel run', so that
	// relative paths make sense.
	if wd := os.Getenv("BUILD_WORKING_DIRECTORY"); wd != "" {
		if err := os.Chdir(wd); err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
	}

	if err := run(ctx, os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string) error {
	flags := flag.NewFlagSet("notificationqueue", flag.ContinueOnError)
	var service, tlsClientAuthCert, tlsClientAuthKey string
	flags.StringVar(&service, "service", "", "The remote service to connect to via gRPC. Should include hostname and port, like example.com:443.")
	flags.StringVar(&tlsClientAuthCert, "tls_client_auth_cert", "", "mTLS client certificate file to use when connecting to the gRPC service.")
	flags.StringVar(&tlsClientAuthKey, "tls_client_auth_key", "", "mTLS client key file to use when connecting to the gRPC service.")
	if err := flags.Parse(args); errors.Is(err, flag.ErrHelp) {
		fmt.Println(helpMessage)
		return nil
	} else if err != nil {
		return err
	}
	if flags.NArg() > 0 {
		return fmt.Errorf("expected no arguments")
	}
	if service == "" {
		return fmt.Errorf("-service not set; expected a hostname and port like 'example.cluster.engflow.com:443'")
	}
	if tlsClientAuthCert == "" {
		return fmt.Errorf("-tls_client_auth_cert not set")
	}
	if tlsClientAuthKey == "" {
		return fmt.Errorf("-tls_client_auth_key not set")
	}

	cert, err := tls.LoadX509KeyPair(tlsClientAuthCert, tlsClientAuthKey)
	if err != nil {
		return err
	}
	creds := credentials.NewTLS(&tls.Config{Certificates: []tls.Certificate{cert}})
	conn, err := grpc.NewClient(service, grpc.WithTransportCredentials(creds))
	if err != nil {
		return err
	}
	defer conn.Close()

	client := notificationv1.NewNotificationQueueClient(conn)
	return streamNotifications(ctx, client, resourceUsageQueueName, printNotification)
}

// streamNotifications calls the NotificationQueue/Pull RPC and handles
// notification acknowledgement. It calls f with each acknowledged notification.
func streamNotifications(
	ctx context.Context,
	client notificationv1.NotificationQueueClient,
	queueName string,
	f func(*notificationv1.Notification) error,
) (err error) {
	defer func() {
		if err != nil {
			err = fmt.Errorf("streaming resource usage events: %w", err)
		}
	}()
	if ctx.Err() != nil {
		return ctx.Err()
	}

	// Create a separate context for the stream to attempt graceful termination.
	// We want to avoid a race where the user cancels the parent context
	// (by pressing ^C), and we've received and printed but not acknowledged
	// an event.
	streamCtx, cancel := context.WithCancel(ctx)
	defer cancel()
	go func() {
		select {
		case <-streamCtx.Done():
			// Stream finished first.
		case <-ctx.Done():
			// Caller canceled. Wait a few seconds, then cancel the stream context.
			t := time.NewTimer(5 * time.Second)
			defer t.Stop()
			select {
			case <-streamCtx.Done():
			case <-t.C:
				cancel()
			}
		}
	}()

	// Open the stream and send the first request. We only need to say which
	// queue we're interested in.
	stream, err := client.Pull(streamCtx)
	if err != nil {
		return fmt.Errorf("opening stream: %w", err)
	}
	firstReq := &notificationv1.PullNotificationRequest{
		Queue: &notificationv1.QueueId{
			Name: queueName,
		},
	}
	if err := stream.Send(firstReq); err != nil {
		return fmt.Errorf("sending first request: %w", err)
	}

	// Receive and acknowledge events. The server keeps streaming until
	// this client closes this stream when the parent context is canceled.
	ackRetries := make(map[string]int)
	for {
		// Receive the next response. If streamCtx is canceled, this returns
		// an error immediately.
		resp, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			return nil
		} else if err != nil {
			return err
		}

		// Process the new notification if there is one. We process it immediately
		// THEN acknowledge it. This could result in processing the same event
		// twice if the acknowledgement fails, but that's better than losing
		// the event entirely if we did it in the opposite order. Events have
		// unique IDs and can be deduplicated by the processor. We do not process
		// or acknowledge events after the parent context is canceled.
		if unacknowledgedNotification := resp.GetNotification(); ctx.Err() == nil && unacknowledgedNotification != nil {
			token := unacknowledgedNotification.GetToken()
			notification := unacknowledgedNotification.GetNotification()
			ackRetries[token] = 0
			ackReq := &notificationv1.PullNotificationRequest{AcknowledgementTokens: []string{token}}
			if err := stream.Send(ackReq); err != nil {
				return fmt.Errorf("failed to send notification acknowledgement: %w", err)
			}
			if err := f(notification); err != nil {
				return err
			}
		}

		// Process acknowledgement receipts, even after streamCtx is canceled.
		// If a notification is successfully acknowledged, send to the caller.
		// If a notification failed to be acknowledged, retry or fail.
		for _, receipt := range resp.GetAcknowledgementReceipt() {
			token := receipt.GetToken()
			if _, ok := ackRetries[token]; !ok {
				return fmt.Errorf("server acknowledged unknown notification with token %q", token)
			}

			switch codes.Code(receipt.GetStatus().GetCode()) {
			case codes.OK:
				delete(ackRetries, token)

			case codes.DeadlineExceeded, codes.ResourceExhausted, codes.Internal, codes.Unavailable:
				ackRetries[token]++
				if ackRetries[token] >= maxRetries {
					return fmt.Errorf("server failed to acknowledge notification: %w", status.ErrorProto(receipt.GetStatus()))
				}
				ackReq := &notificationv1.PullNotificationRequest{AcknowledgementTokens: []string{token}}
				if err := stream.Send(ackReq); err != nil {
					return fmt.Errorf("failed to retry notification acknowledgement: %w", err)
				}

			default:
				return fmt.Errorf("server failed to acknowledge notification: %w", status.ErrorProto(receipt.GetStatus()))
			}
		}

		if ctx.Err() != nil && len(ackRetries) == 0 {
			// Parent context canceled, and we've successfully acknowledged all
			// processed events. Close this end of the stream to tell the server
			// we won't acknowledge any more. The server should close its end, too.
			if err := stream.CloseSend(); err != nil {
				return fmt.Errorf("closing stream: %w", err)
			}
		}
	}
}

// printNotification unmarshals a notification as a Resource Usage event
// and prints it to stdout as JSON.
func printNotification(notification *notificationv1.Notification) (err error) {
	defer func() {
		if err != nil {
			err = fmt.Errorf("processing event id=%s: %w", notification.GetId(), err)
		}
	}()
	timestamp := notification.GetTimestamp().AsTime()
	usageEvent := new(resourceusagev1.ResourceUsageEvent)
	if err := notification.GetPayload().UnmarshalTo(usageEvent); err != nil {
		return fmt.Errorf("unmarshaling notification payload: %w", err)
	}

	out := resourceUsageJSON{
		ID:        notification.GetId(),
		Timestamp: timestamp,
		Dimension: make(map[string]string),
		Tag:       make(map[string]string),
	}
	for _, dimension := range usageEvent.GetDimension() {
		out.Dimension[dimension.GetKey()] = dimension.GetValue()
	}
	for _, tag := range usageEvent.GetTag() {
		out.Tag[tag.GetKey()] = tag.GetValue()
	}

	for _, payload := range usageEvent.GetPayload() {
		switch {
		case payload.MessageIs((*resourceusagev1.Compute)(nil)):
			compute := new(resourceusagev1.Compute)
			if err := payload.UnmarshalTo(compute); err != nil {
				return fmt.Errorf("unmarshaling compute payload: %w", err)
			}
			out.Compute = &computeJSON{Duration: compute.GetDuration().AsDuration()}

		case payload.MessageIs((*resourceusagev1.Network)(nil)):
			network := new(resourceusagev1.Network)
			if err := payload.UnmarshalTo(network); err != nil {
				return fmt.Errorf("unmarshaling network payload: %w", err)
			}
			out.Network = &networkJSON{
				UploadedBytes:   network.GetUploadedBytes(),
				DownloadedBytes: network.GetDownloadedBytes(),
			}

		case payload.MessageIs((*resourceusagev1.Storage)(nil)):
			storage := new(resourceusagev1.Storage)
			if err := payload.UnmarshalTo(storage); err != nil {
				return fmt.Errorf("unmarshaling storage payload: %w", err)
			}
			out.Storage = &storageJSON{
				StoredBytes: storage.GetStoredBytes(),
				Duration:    storage.GetDuration().AsDuration(),
			}

		default:
			return fmt.Errorf("unknown payload type")
		}
	}

	bs, err := json.MarshalIndent(out, "", "  ")
	if err != nil {
		return err
	}
	fmt.Printf("%s\n", bs)
	return nil
}

type resourceUsageJSON struct {
	ID        string
	Timestamp time.Time
	Dimension map[string]string
	Tag       map[string]string
	Compute   *computeJSON `json:",omitempty"`
	Network   *networkJSON `json:",omitempty"`
	Storage   *storageJSON `json:",omitempty"`
}

type computeJSON struct {
	Duration time.Duration
}

type networkJSON struct {
	UploadedBytes, DownloadedBytes uint64
}

type storageJSON struct {
	StoredBytes uint64
	Duration    time.Duration
}
