# Using the notification queue and event store APIs

This documents explains how to make use of the **notification queue API** to
obtain the notifications for a given build and use the notification data
to obtain invocation events from the **event store API**. To do so,
the [EngFlow API](https://github.com/EngFlow/engflowapis) is used as external
dependency (see [WORKSPACE](../../../../WORKSPACE)).

# Running the client

In order to execute the client example, you must pass the following arguments
that depends on the target cluster. 

1. `--notification_queue_endpoint=CLUSTER_URL` holds the `grpc/grpcs` endpoint of the cluster
2. `--queue_name=eventstore/lifecycle-events` holds the name of the queue to listen 
3. `--tls_certificate=/path/to/your/client.crt` holds the path of the crt file to access the cluster
4. `--tls_key=/path/to/your/client.key` holds the path of the key file used to access the cluster

```
bazel run //java/com/engflow/notificationqueue/client  -- \
      --notification_queue_endpoint=CLUSTER_URL --queue_name=eventstore/lifecycle-events \
      --tls_certificate=/path/to/your/client.crt --tls_key=/path/to/your/client.key
```

At this point, the client should be listening to the lifecycle events of the cluster. It then remains
to build something and to get its notifications and invocations.


# Executing a foo application

You may now build any targets using 

```
bazel --ignore_all_rc_files build //... --remote_cache=CLUSTER_URL --bes_backend=CLUSTER_URL
```

You should see a series of notifications like this one

```
type_url: "type.googleapis.com/engflow.eventstore.v1.BuildLifecycleEventNotification"
value: "\022$e03d2afe-1a78-4f14-a0f7-85ae65e7e856\"%user_keyword=engflow:StreamSource=BES\"/user_keyword=engflow:StreamType=ClientBEPStream\272\006&\n$1e4f34ee-4669-4ce0-a3fe-5e115ad4772e"
```

The value, with some garbage characters, contains the uuid for one invocation.
Using this uuid we may get an invocation like this one

```
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
