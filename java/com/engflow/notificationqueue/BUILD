package(default_visibility = ["//visibility:public"])
load("@io_grpc_grpc_java//:java_grpc_library.bzl", "java_grpc_library")

java_proto_library(
    name = "engflowapis_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        "@com_engflow_engflowapis//engflow/eventstore/v1:build_event_proto",
        "@com_engflow_engflowapis//engflow/eventstore/v1:eventstore_proto",
        "@com_engflow_engflowapis//engflow/eventstore/v1:notifications_proto",
        "@com_engflow_engflowapis//engflow/notification/v1:notification_proto",
        "@com_engflow_engflowapis//engflow/notification/v1:notification_queue_proto",
    ],
)

java_grpc_library(
    name = "notification_queue_java_grpc",
    srcs = [
        "@com_engflow_engflowapis//engflow/notification/v1:notification_queue_proto",
    ],
    deps = [
        ":engflowapis_java_proto",
    ],
)

java_grpc_library(
    name = "eventstore_java_grpc",
    srcs = [
        "@com_engflow_engflowapis//engflow/eventstore/v1:eventstore_proto",
    ],
    deps = [
        ":engflowapis_java_proto",
    ],
)

java_binary(
    name = "client",
    srcs = [
        "Client.java",
    ],
    main_class = "com.engflow.notificationqueue.Client",
    deps = [
        ":notification_queue_java_grpc",
        ":eventstore_java_grpc",
        ":engflowapis_java_proto",
        "@com_google_protobuf//:any_proto",
        "@com_google_protobuf//java/core",
        "@io_grpc_grpc_java//api",
        "@io_grpc_grpc_java//netty",
        "@io_grpc_grpc_java//protobuf",
        "@io_grpc_grpc_java//stub",
        "@maven//:com_google_guava_guava",
        "@maven//:io_netty_netty_handler",
        "@maven//:com_google_code_findbugs_jsr305"
    ],
)
