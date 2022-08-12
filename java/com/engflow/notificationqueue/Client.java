package com.engflow.notificationqueue;

import com.engflow.eventstore.v1.BuildLifecycleEventNotification;
import com.engflow.eventstore.v1.EventStoreGrpc;
import com.engflow.eventstore.v1.GetInvocationRequest;
import com.engflow.eventstore.v1.StreamedBuildEvent;
import com.engflow.notification.v1.Notification;
import com.engflow.notification.v1.NotificationQueueGrpc;
import com.engflow.notification.v1.PullNotificationRequest;
import com.engflow.notification.v1.PullNotificationResponse;
import com.engflow.notification.v1.QueueId;
import com.google.common.base.Preconditions;
import com.google.common.base.Strings;
import com.google.protobuf.Any;
import com.google.protobuf.InvalidProtocolBufferException;
import io.grpc.ManagedChannel;
import io.grpc.Metadata;
import io.grpc.netty.GrpcSslContexts;
import io.grpc.netty.NegotiationType;
import io.grpc.netty.NettyChannelBuilder;
import io.grpc.stub.MetadataUtils;
import io.grpc.stub.StreamObserver;
import io.netty.handler.ssl.SslContextBuilder;
import java.io.File;
import java.io.IOException;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import javax.annotation.Nullable;
import javax.net.ssl.SSLException;

class Client {

  public static void main(String[] args) throws Exception {
    NotificationOptions clientOptions;
    try {
      clientOptions = new NotificationOptions().parseOptions(args);
    } catch (IllegalArgumentException e) {
      System.err.println(e);
      System.err.println(" --notification_queue_endpoint");
      System.err.println(" --queue_name");
      System.err.println("Please provide also authentication credentials");
      return;
    }

    /**
     * Channel used by the NotificationQueueGrpc and the EventStoreGrpc stub. It is also possible to
     * use two separated channels.
     */
    ManagedChannel channel = null;
    try {
      channel =
          createChannel(
              clientOptions.getOption("notification_queue_endpoint"),
              clientOptions.getOption("tls_certificate"),
              clientOptions.getOption("tls_key"));

    } catch (IllegalArgumentException e) {
      System.err.println("Unable to open channel to " + args[0].split("=")[1]);
      throw new IllegalArgumentException(e);
    } catch (IllegalStateException e) {
      System.err.println("Unable to open channel to " + args[0].split("=")[1]);
      throw new IllegalStateException(e);
    } catch (IOException e) {
      throw new IOException(e);
    }
    try {
      final Metadata header = new Metadata();
      Metadata.Key<String> userKey =
          Metadata.Key.of("Authorization", Metadata.ASCII_STRING_MARSHALLER);
      header.put(userKey, "Bearer " + clientOptions.getOption("token"));
      pull(channel, clientOptions.getOption("queue_name"), header);
    } finally {
      if (channel != null) {
        channel.shutdownNow();
        try {
          channel.awaitTermination(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
          System.out.println("Could not shut down channel within timeout");
        }
      }
    }
  }

  /**
   * Gets the notification streams from a {@link NotificationQueueGrpc} stub and then calls
   * getInvocation for each received notification
   *
   * @param channel a grpc channel for cluster connection
   * @param queueName name of the queue to listen to
   * @param header metadata for token authentication (if needed)
   * @throws InterruptedException
   */
  private static void pull(ManagedChannel channel, String queueName, Metadata header)
      throws InterruptedException {
    NotificationQueueGrpc.NotificationQueueStub asyncStub = NotificationQueueGrpc.newStub(channel);
    asyncStub = MetadataUtils.attachHeaders(asyncStub, header);
    final CountDownLatch finishLatch = new CountDownLatch(1);
    StreamObserver<PullNotificationRequest> requestObserver =
        asyncStub.pull(
            new StreamObserver<PullNotificationResponse>() {
              @Override
              public void onNext(PullNotificationResponse response) {
                Notification streamedNotification = response.getNotification().getNotification();
                System.out.println("Notification: " + streamedNotification);
                Any notificationContent = streamedNotification.getPayload();
                try {
                  BuildLifecycleEventNotification lifeCycleEvent =
                      notificationContent.unpack(BuildLifecycleEventNotification.class);
                  /**
                   * Check if this is an invocation started event. Options are INVOCATION_STARTED
                   * and INVOCATION_FINISHED
                   */
                  if (lifeCycleEvent.getKindCase().name().equals("INVOCATION_STARTED")) {
                    String invocation = lifeCycleEvent.getInvocationStarted().getInvocationId();
                    try {
                      /**
                       * Fetch the invocation using the grpc {@link EventStoreGrpc} stub using the
                       * acquired invocation id
                       */
                      getInvocations(channel, invocation, header);
                    } catch (InterruptedException e) {
                      System.err.println("Could not get invocation with uuid " + invocation);
                    }
                  }

                } catch (InvalidProtocolBufferException e) {
                  throw new RuntimeException(e);
                }
              }

              @Override
              public void onError(Throwable t) {
                System.err.println("Error on request: " + t.getMessage());
                finishLatch.countDown();
              }

              @Override
              public void onCompleted() {
                System.out.println("Finished pulling notifications");
                finishLatch.countDown();
              }
            });

    try {
      requestObserver.onNext(
          PullNotificationRequest.newBuilder()
              .setQueue(QueueId.newBuilder().setName(queueName).build())
              .build());
    } catch (RuntimeException e) {
      // Cancel RPC
      requestObserver.onError(e);
      throw e;
    }

    finishLatch.await();
  }

  /**
   * Gets an invocation from the {@link EventStoreGrpc} stub
   *
   * @param channel a grpc channel for cluster connection
   * @param invocationId the id of the required notification
   * @param header metadata for token authentication (if needed)
   * @throws InterruptedException
   */
  public static void getInvocations(ManagedChannel channel, String invocationId, Metadata header)
      throws InterruptedException {
    EventStoreGrpc.EventStoreStub asyncStub = EventStoreGrpc.newStub(channel);
    asyncStub = MetadataUtils.attachHeaders(asyncStub, header);
    asyncStub.getInvocation(
        GetInvocationRequest.newBuilder().setInvocationId(invocationId).build(),
        new StreamObserver<StreamedBuildEvent>() {
          @Override
          public void onNext(StreamedBuildEvent response) {
            System.out.println("Invocation: " + response.toString());
          }

          @Override
          public void onError(Throwable t) {
            System.err.println("Error on request: " + t.getMessage());
          }

          @Override
          public void onCompleted() {
            System.out.println("Finished pulling invocation");
          }
        });
  }

  private static ManagedChannel createChannel(
      String endpoint, @Nullable String clientCertificate, @Nullable String clientKey)
      throws IOException {
    Preconditions.checkArgument(
        !Strings.isNullOrEmpty(endpoint),
        "Empty --notification_queue_endpoint, expected \"protocol://host[:port]\"");

    boolean tls = endpoint.startsWith("grpcs://");
    Preconditions.checkArgument(
        tls || endpoint.startsWith("grpc://"),
        "Bad --notification_queue_endpoint value \""
            + endpoint
            + "\", expected \"grpc://\" or \"grpcs://\" protocol");
    endpoint = endpoint.substring(tls ? "grpcs://".length() : "grpc://".length());

    NettyChannelBuilder builder =
        NettyChannelBuilder.forTarget(endpoint)
            .negotiationType(tls ? NegotiationType.TLS : NegotiationType.PLAINTEXT);

    if (tls) {
      try {
        SslContextBuilder contextBuilder = GrpcSslContexts.forClient();
        if (!Strings.isNullOrEmpty(clientCertificate) && !Strings.isNullOrEmpty(clientKey)) {
          contextBuilder =
              contextBuilder.keyManager(new File(clientCertificate), new File(clientKey));
        }
        builder.sslContext(contextBuilder.build());
      } catch (SSLException e) {
        throw new IllegalStateException(e);
      } catch (IOException e) {
        throw new IOException(e);
      }
    }
    return builder.build();
  }
}
