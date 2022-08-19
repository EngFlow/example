package com.engflow.notificationqueue.demoserver;

import io.grpc.Server;
import io.grpc.ServerBuilder;
import io.grpc.stub.StreamObserver;
import java.io.IOException;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

class DemoServer {
  private static final Logger logger = Logger.getLogger(DemoServer.class.getName());

  private Server server;

  private void start() throws IOException {
    /* The port on which the server should run */
    int port = 50051;
    server = ServerBuilder.forPort(port).addService(new ForwardingImpl()).build().start();
    logger.info("Server started, listening on " + port);
    Runtime.getRuntime()
        .addShutdownHook(
            new Thread() {
              @Override
              public void run() {
                // Use stderr here since the logger may have been reset by its JVM shutdown hook.
                System.err.println("*** shutting down gRPC server since JVM is shutting down");
                try {
                  DemoServer.this.stop();
                } catch (InterruptedException e) {
                  e.printStackTrace(System.err);
                }
                System.err.println("*** server shut down");
              }
            });
  }

  private void stop() throws InterruptedException {
    if (server != null) {
      server.shutdown().awaitTermination(30, TimeUnit.SECONDS);
    }
  }

  /** Await termination on the main thread since the grpc library uses daemon threads. */
  private void blockUntilShutdown() throws InterruptedException {
    if (server != null) {
      server.awaitTermination();
    }
  }

  /** Main launches the server from the command line. */
  public static void main(String[] args) throws IOException, InterruptedException {
    final DemoServer server = new DemoServer();
    server.start();
    server.blockUntilShutdown();
  }

  static class ForwardingImpl extends ForwardingGrpc.ForwardingImplBase {

    @Override
    public void forwardStream(
        EngFlowRequest req, StreamObserver<EngFlowResponse> responseObserver) {
      System.out.println("Receiving data... id " + req.getId() + ", payload " + req.getPayload());
      EngFlowResponse response =
          EngFlowResponse.newBuilder()
              .setMessage("Processed request with id " + req.getId() + " in the server.")
              .build();
      responseObserver.onNext(response);
      responseObserver.onCompleted();
    }
  }
}
