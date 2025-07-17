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
a connection to the EngFlow cluster, unless the cluster is totally open.
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


### Using JWT to run the client

In the second for case authentication you should have a valid token. On EngFlow clusters you may get a new access token by
accessing the cluster's UI under the tab `Getting Started`. To execute the client against your cluster, add the argument

1. `--token=your-long-JWT-token`
   holds the authentication token.
   Needed for both `grpc://` and `grpcs://` connections

Run the client using

```bash
bazel run //java/com/engflow/notificationqueue:client  -- \
      '--notification_queue_endpoint=grpcs://$CLUSTER.cluster.engflow.com' '--queue_name=eventstore/lifecycle-events' \
      '--token=DKiJ3eic9l150dDmzdMsaiu0K5boBle0UlkCefbgwzBE7G7FItgi2AOFpz6pkcMUFV3SkpAGikMckcaQhTTKUmGeZKpLh9gT6vTsi0v'
```


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
{
  type_url: "type.googleapis.com/engflow.eventstore.v1.BuildLifecycleEventNotification"
  value: "\n\adefault\022$9608f439-4c3e-4909-8a0c-f78810322b6b\"\021command_name=test\"\021protocol_name=BEP\"0user_keyword=engflow:CiCdPipelineName=post-merge\"7user_keyword=engflow:CiCdJobName=ci-runners-test-matrix\"\'user_keyword=engflow:Requester=anfelbar\"%user_keyword=engflow:StreamSource=BES\"/user_keyword=engflow:StreamType=ClientBEPStream\272\006&\n$5173658c-4595-4978-8db0-2942b1e7ca13"
}
```

The last value contains the `uuid` for one invocation. From the previous example the invocation `uuid` is `5173658c-4595-4978-8db0-2942b1e7ca13`.
Using this `uuid` and the EventStore stub we get invocation data (see [getInvocations code in Client.java][getinvocations]):

```json
Invocation: continuation_token: "CiQwNzBkMjViZi0zZWFjLTRlYTYtODVhOC00ZjA2NDMxNjU2NTcQAA=="
event {
  stream_id {
    build_id: "3a38c04f-233d-465f-a91d-f328c21ab832"
    invocation_id: "070d25bf-3eac-4ea6-85a8-4f0643165657"
  }
  service_level: INTERACTIVE
  notification_keywords: "command_name=test"
  notification_keywords: "protocol_name=BEP"
  notification_keywords: "user_keyword=engflow:CiCdPipelineName=post-merge"
  notification_keywords: "user_keyword=engflow:CiCdJobName=runners-matrix"
  notification_keywords: "user_keyword=engflow:Requester=userxyz"
  notification_keywords: "user_keyword=engflow:StreamSource=BES"
  notification_keywords: "user_keyword=engflow:StreamType=ClientBEPStream"
  build_event {
    event_time {
      seconds: 1752547458
      nanos: 781000000
    }
    invocation_attempt_started {
      attempt_number: 1
    }
  }
}
```


[server proto definition]: demoserver/server.proto
[getinvocations]: https://github.com/EngFlow/example/blob/c9a30c214d487385313245cca24c6b7f3e867785/java/com/engflow/notificationqueue/Client.java#L201