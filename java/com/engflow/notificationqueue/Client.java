package java.com.engflow.notificationqueue;

import com.engflow.eventstore.v1.BuildLifecycleEventNotification;
import com.engflow.eventstore.v1.EventStoreGrpc;
import com.engflow.eventstore.v1.GetInvocationRequest;
import com.engflow.eventstore.v1.StreamedBuildEvent;
import com.engflow.notification.v1.*;
import com.google.common.base.Preconditions;
import com.google.common.base.Strings;
import com.google.protobuf.Any;
import com.google.protobuf.InvalidProtocolBufferException;
import io.grpc.ManagedChannel;
import io.grpc.netty.GrpcSslContexts;
import io.grpc.netty.NegotiationType;
import io.grpc.netty.NettyChannelBuilder;
import io.grpc.stub.StreamObserver;
import io.netty.handler.ssl.SslContextBuilder;

import javax.annotation.Nullable;
import javax.net.ssl.SSLException;
import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

class Client {

  public static void main(String[] args) throws Exception {
    /**
     * Check for the command line arguments in specific order.
     * In this case, only the presence of the flags are checked.
     * Create appropriated validations when needed.
     */
    if (!areAllInputsProvided(args)){
      System.err.println("Please add the following flags: ");
      System.err.println(" --notification_queue_endpoint");
      System.err.println(" --queue_name");
      System.err.println(" --tls_certificate");
      System.err.println(" --tls_key");
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
              args[0].split("=")[1],
              "",
              args[2].split("=")[1],
              args[3].split("=")[1]);

      pull(channel, args[1]);
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

  private static boolean areAllInputsProvided(String[] args){
    final String[] global_options = {"--notification_queue_endpoint", "--queue_name", "--tls_certificate", "--tls_key"};
    int checks = 0;
    for (String predefinedOption : global_options) {
      for (String givenOption : args) {
        if (predefinedOption.equals(givenOption.substring(0, predefinedOption.length()))){
          checks++;
          break;
        }
      }
    }
    return checks == 4 ? true : false;
  }
  private static void pull(ManagedChannel channel, String queueName) throws InterruptedException {
    NotificationQueueGrpc.NotificationQueueStub asyncStub = NotificationQueueGrpc.newStub(channel);
    final CountDownLatch finishLatch = new CountDownLatch(1);
    StreamObserver<PullNotificationRequest> requestObserver =
        asyncStub.pull(
            new StreamObserver<PullNotificationResponse>() {
              @Override
              public void onNext(PullNotificationResponse response) {
                System.out.println("Nothing here");
                Notification streamedNotification = response.getNotification().getNotification();
                System.out.println("Notification: " + streamedNotification);
                Any notificationContent = streamedNotification.getPayload();
                try {
                  BuildLifecycleEventNotification lifeCycleEvent =
                      notificationContent.unpack(BuildLifecycleEventNotification.class);
                  // Check if this is an invocation started event
                  if (lifeCycleEvent.getKindCase().name().equals("INVOCATION_STARTED")) {
                    String invocation = lifeCycleEvent.getInvocationStarted().getInvocationId();
                    try {
                      getInvocations(channel, invocation);
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

  public static void getInvocations(ManagedChannel channel, String invocationId)
      throws InterruptedException {
    EventStoreGrpc.EventStoreStub asyncStub = EventStoreGrpc.newStub(channel);
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
      String endpoint,
      String tlsTrustedCertificate,
      @Nullable String clientCertificate,
      @Nullable String clientKey) {
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
        if (!Strings.isNullOrEmpty(tlsTrustedCertificate)) {
          File cert = new File(tlsTrustedCertificate);
          if (!cert.isFile()) {
            throw new IllegalArgumentException(
                "\"--tls_trusted_certificate\" must point to an existing file");
          }
          contextBuilder = contextBuilder.trustManager(cert);
        }
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
