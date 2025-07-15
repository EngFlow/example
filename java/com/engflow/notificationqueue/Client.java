package com.engflow.notificationqueue;

import com.engflow.eventstore.v1.proto.BuildLifecycleEventNotification;
import com.engflow.eventstore.v1.proto.EventStoreGrpc;
import com.engflow.eventstore.v1.proto.GetInvocationRequest;
import com.engflow.eventstore.v1.proto.StreamedBuildEvent;
import com.engflow.notification.v1.proto.Notification;
import com.engflow.notification.v1.proto.NotificationQueueGrpc;
import com.engflow.notification.v1.proto.PullNotificationRequest;
import com.engflow.notification.v1.proto.PullNotificationResponse;
import com.engflow.notification.v1.proto.QueueId;
import com.engflow.notificationqueue.demoserver.EngFlowRequest;
import com.engflow.notificationqueue.demoserver.EngFlowResponse;
import com.engflow.notificationqueue.demoserver.ForwardingGrpc;
import com.google.common.base.Preconditions;
import com.google.common.base.Strings;
import com.google.protobuf.Any;
import com.google.protobuf.InvalidProtocolBufferException;
import io.grpc.ManagedChannel;
import io.grpc.Metadata;
import io.grpc.StatusRuntimeException;
import io.grpc.netty.GrpcSslContexts;
import io.grpc.netty.NegotiationType;
import io.grpc.netty.NettyChannelBuilder;
import io.grpc.stub.ClientCallStreamObserver;
import io.grpc.stub.ClientResponseObserver;
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
      System.err.println(
          "Please provide also authentication credentials "
              + "and if you want to forward then add another external server endpoint");
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
    }

    ManagedChannel forwardChannel = null;
    if (!Strings.isNullOrEmpty(clientOptions.getOption("forward"))) {
      try {
        forwardChannel = createChannel(clientOptions.getOption("forward"), null, null);
      } catch (IllegalArgumentException e) {
        System.err.println("Could not open forwarding channel");
      } catch (IllegalStateException e) {
        System.err.println("Could not open forwarding channel");
      } catch (IOException e) {
        System.err.println("Could not open forwarding channel");
      }
    }
    try {
      final Metadata header = new Metadata();
      Metadata.Key<String> userKey =
          Metadata.Key.of("Authorization", Metadata.ASCII_STRING_MARSHALLER);
      header.put(userKey, "Bearer " + clientOptions.getOption("token"));
      pull(channel, clientOptions.getOption("queue_name"), header, forwardChannel);
    } finally {
      if (channel != null) {
        channel.shutdownNow();
        if (forwardChannel != null) {
          forwardChannel.shutdownNow();
        }
        try {
          channel.awaitTermination(10, TimeUnit.SECONDS);
          if (forwardChannel != null) {
            forwardChannel.awaitTermination(10, TimeUnit.SECONDS);
          }
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
  private static void pull(
      ManagedChannel channel, String queueName, Metadata header, ManagedChannel forwardChannel)
      throws InterruptedException {

    NotificationQueueGrpc.NotificationQueueStub asyncStub = NotificationQueueGrpc.newStub(channel);
    asyncStub = asyncStub.withInterceptors(MetadataUtils.newAttachHeadersInterceptor(header));
    final CountDownLatch finishLatch = new CountDownLatch(1);
    System.out.println("Listening for build events...");
    var observer =
        new ClientResponseObserver<PullNotificationRequest, PullNotificationResponse>() {
          private ClientCallStreamObserver<PullNotificationRequest> requestStream;

          @Override
          public void beforeStart(ClientCallStreamObserver<PullNotificationRequest> requestStream) {
            this.requestStream = requestStream;
          }

          @Override
          public void onNext(PullNotificationResponse response) {
            if (!response.hasNotification()) {
              return;
            }
            Notification streamedNotification = response.getNotification().getNotification();
            System.out.println("Notification: " + streamedNotification.toString());
            try {
              /** Forward notification data to external server */
              forwardToBESStub(
                  forwardChannel,
                  streamedNotification.getId().toString(),
                  streamedNotification.getPayload().toString());
            } catch (Exception e) {
              System.err.println("Could not forward notification to external sever...");
            }
            Any notificationContent = streamedNotification.getPayload();
            try {
              BuildLifecycleEventNotification lifeCycleEvent =
                  notificationContent.unpack(BuildLifecycleEventNotification.class);
              /**
               * Check if this is an invocation finished event.
               */
              if (lifeCycleEvent.getKindCase().name().equals("INVOCATION_FINISHED")) {
                String invocation = lifeCycleEvent.getInvocationFinished().getInvocationId();
                try {
                  /**
                   * Fetch the invocation using the grpc {@link EventStoreGrpc} stub using the
                   * acquired invocation id
                   */
                  getInvocations(channel, invocation, header, forwardChannel);
                } catch (InterruptedException e) {
                  System.err.println("Could not get invocation with uuid " + invocation);
                }
              }

            } catch (InvalidProtocolBufferException e) {
              throw new RuntimeException(e);
            }
            requestStream.onNext(
                PullNotificationRequest.newBuilder()
                    .addAcknowledgementTokens(response.getNotification().getToken())
                    .build());
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
        };
    asyncStub.pull(observer);

    observer.requestStream.onNext(
        PullNotificationRequest.newBuilder()
            .setQueue(QueueId.newBuilder().setName(queueName).build())
            .build());

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
  private static void getInvocations(
      ManagedChannel channel, String invocationId, Metadata header, ManagedChannel forwardChannel)
      throws InterruptedException {
    EventStoreGrpc.EventStoreStub asyncStub = EventStoreGrpc.newStub(channel);
    asyncStub = asyncStub.withInterceptors(MetadataUtils.newAttachHeadersInterceptor(header));
    asyncStub.getInvocation(
        GetInvocationRequest.newBuilder().setInvocationId(invocationId).build(),
        new StreamObserver<StreamedBuildEvent>() {
          @Override
          public void onNext(StreamedBuildEvent response) {
            System.out.println("Invocation: " + response.toString());
            String buildEvent = response.getEvent().toString();
            try {
              /** Forward invocation data to external server */
              forwardToBESStub(forwardChannel, invocationId, buildEvent);
            } catch (Exception e) {
              System.err.println("Could not forward invocation to external sever...");
            }
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

  /**
   * Forwards data to an external grpc stub.
   *
   * @param channel a grpc channel for connection
   * @param id the id of the data to send
   * @param payload the payload
   */
  private static void forwardToBESStub(ManagedChannel channel, String id, String payload) {
    if (channel == null) {
      return;
    }
    final ForwardingGrpc.ForwardingBlockingStub blockingStub =
        ForwardingGrpc.newBlockingStub(channel);
    EngFlowRequest request = EngFlowRequest.newBuilder().setId(id).setPayload(payload).build();
    EngFlowResponse response;
    try {
      response = blockingStub.forwardStream(request);
      System.out.println("Forwarding: " + response.getMessage());
    } catch (StatusRuntimeException e) {
      System.out.println("Could not forward data to external server.");
      return;
    }
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
      }
    }
    return builder.build();
  }
}