# Using the notification queue and event store APIs

This document explains how to make use of the **notification queue API** to
obtain the notifications for a given build and use the notification data
to obtain invocation events from the **event store API**. To do so,
the [EngFlow API](https://github.com/EngFlow/engflowapis) is used as external
dependency (see [WORKSPACE](../../../../WORKSPACE)).

# Running the client

The first argument you must have to execute the client is the cluster `grpc` endpoint
you want to listen to.
The second argument is the queue name. As in this example we are interested in
getting lifecycle events from the cluster, we pull from the queue called `lifecycle-events`.

1. `--notification_queue_endpoint=CLUSTER_URL`  the URL of the cluster gRPC
   server. Must start with `grpc://` or `grpcs://`
2. `--queue_name=eventstore/lifecycle-events` holds the name of the queue to listen

Next, you must provide authentication information so the client can establish
a connection to the engflow cluster, unless the cluster is totally open.
As for today, two authentication methods are available; certificates or
authentication tokens. These arguments are optional and if they are not given
but are required by the cluster, the connection is rejected.

### Using certificates to run the client

In the first case you should have valid credentials in `.crt` and `.key` files. Add
the full path of your certificate files into the following options

1. `--tls_certificate=certificate file containing your public key` 
    holds the path of the crt file to access the cluster.
    Only needed for `grpcs://` connections
2. `--tls_key=/path/to/your/file containing your private key` 
    holds the path of the key file used to access the cluster.
    Only needed for `grpcs://` connections

Run the client using

```bash
bazel run //java/com/engflow/notificationqueue:client  -- \
      '--notification_queue_endpoint=grpcs://example.cluster.engflow.com' '--queue_name=eventstore/lifecycle-events' \
      '--tls_certificate=example_client.crt' '--tls_key=example_client.key'
```


### Using tokens to run the client

In the second for case authentication you should have a token issued by a
valid authority. In this example we use cluster used by the 
[open-source envoy-mobile](https://github.com/envoyproxy/envoy-mobile) project. 
It uses [GitHub tokens](https://docs.github.com/en/actions/security-guides/automatic-token-authentication) for authentication method but your server may support 
other token provider. To execute the client against the envoy-mobile cluster add
the argument

1. `--token=token issued by valid authority`
   holds the authentication token.
   Needed for both `grpc://` and `grpcs://` connections

Run the client using

```bash
bazel run //java/com/engflow/notificationqueue:client  -- \
      '--notification_queue_endpoint=grpcs://envoy.cluster.engflow.com' '--queue_name=eventstore/lifecycle-events' \
      '--token=ghs_vHu2hAHwhg2EjBXrs4koOxk5PfSKVb2lzAUM'
```

Note: The token provided in the example is not valid. You should count with a 
valid envoy-mobile token to use envoy-cluster. Change your target cluster and
acquire a valid token for executing the client.

### Forwarding data to external server

One useful use case for the **notification** and **event store APIs** is forwarding the
received data to external servers, for instance another _build event store_ or _result store_ sever.
The current client example implements communication
with a demo grpc stub. To do so, the client uses `Request` and `Response`
abstractions provided by a [server proto definition].

To execute a client that forwards information to an external server you add the flag
`--forward`. Let us first execute a demonstration server that will receive the data from 
the client. To execute the server run

```bash
bazel run //java/com/engflow/notificationqueue/demoserver:server
```

This will start the demo server listening at `localhost:50051`. Now you can start the client with a given
authentication method and the forwarding endpoint

```bash
bazel run //java/com/engflow/notificationqueue:client  -- \
      '--notification_queue_endpoint=grpcs://example.cluster.engflow.com' '--queue_name=eventstore/lifecycle-events' \
      '--tls_certificate=example_client.crt' '--tls_key=example_client.key' '--forward=grpc://localhost:50051'
```

# Executing a foo application

You may now build any targets on the cluster. Open your favorite foo project and build it using
the runtime flags `remote_cache` and `bes_backend` arguments like this

```bash
bazel build //... '--remote_cache=grpcs://example.cluster.engflow.com' '--bes_backend=grpcs://example.cluster.engflow.com'
```

You should see a series of notifications like this one

```json
type_url: "type.googleapis.com/engflow.eventstore.v1.BuildLifecycleEventNotification"
value: "\022$e03d2afe-1a78-4f14-a0f7-85ae65e7e856\"%user_keyword=engflow:StreamSource=BES\"/user_keyword=engflow:StreamType=ClientBEPStream\272\006&\n$1e4f34ee-4669-4ce0-a3fe-5e115ad4772e"
```

The value, with some garbage characters, contains the uuid for one invocation.
Using this uuid we may get an invocation like this one

```json
StreamedBuildEvent: continuation_token: "CiQyMWFjMDlkNC0zZWIzLTQ2MzQtODI0MS0yMzk0Y2JhN2UwMGEQARjSCiAB"
event {
  stream_id {
    build_id: "c88d85cb-08c5-4227-9a24-8e6ea8f262d8"
    component: TOOL
    invocation_id: "21ac09d4-3eb3-4634-8241-2394cba7e00a"
  }
  build_event {
    event_time {
      seconds: 1658502561
      nanos: 364000000
    }
    component_stream_finished {
      type: FINISHED
    }
  }
}
```


[server proto definition]: demoserver/server.proto