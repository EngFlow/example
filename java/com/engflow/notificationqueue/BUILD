package(default_visibility = ["//visibility:public"])

load("@io_grpc_grpc_java//:java_grpc_library.bzl", "java_grpc_library")

java_proto_library(
    name = "engflowapis_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        "@com_engflow_engflowapis//engflow/eventstore/v1:build_event",
        "@com_engflow_engflowapis//engflow/eventstore/v1:eventstore",
        "@com_engflow_engflowapis//engflow/eventstore/v1:notifications",
        "@com_engflow_engflowapis//engflow/notification/v1:notification",
        "@com_engflow_engflowapis//engflow/notification/v1:notification_queue",
    ],
)

java_grpc_library(
    name = "notification_queue_java_grpc",
    srcs = [
        "@com_engflow_engflowapis//engflow/notification/v1:notification_queue",
    ],
    deps = [
        ":engflowapis_java_proto",
    ],
)

java_grpc_library(
    name = "eventstore_java_grpc",
    srcs = [
        "@com_engflow_engflowapis//engflow/eventstore/v1:eventstore",
    ],
    deps = [
        ":engflowapis_java_proto",
    ],
)

java_binary(
    name = "client",
    srcs = [
        "Client.java",
        "NotificationOptions.java",
    ],
    main_class = "com.engflow.notificationqueue.Client",
    deps = [
        ":engflowapis_java_proto",
        ":eventstore_java_grpc",
        ":notification_queue_java_grpc",
        "//java/com/engflow/notificationqueue/demoserver:server_java_grpc_proto",
        "//java/com/engflow/notificationqueue/demoserver:server_java_proto",
        "//java/com/engflow/notificationqueue/demoserver:server_proto",
        "@com_google_protobuf//:any_proto",
        "@com_google_protobuf//java/core",
        "@io_grpc_grpc_java//api",
        "@io_grpc_grpc_java//context",
        "@io_grpc_grpc_java//netty",
        "@io_grpc_grpc_java//stub",
        "@maven//:com_google_code_findbugs_jsr305",
        "@maven//:com_google_guava_guava",
        "@maven//:commons_cli_commons_cli",
        "@maven//:io_netty_netty_handler",
    ],
)
