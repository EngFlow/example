package(default_visibility = ["//visibility:public"])

load("@io_grpc_grpc_java//:java_grpc_library.bzl", "java_grpc_library")

java_binary(
    name = "client",
    srcs = [
        "Client.java",
        "NotificationOptions.java",
    ],
    main_class = "com.engflow.notificationqueue.Client",
    deps = [
        "//java/com/engflow/notificationqueue/demoserver:server_java_grpc_proto",
        "//java/com/engflow/notificationqueue/demoserver:server_java_proto",
        "//java/com/engflow/notificationqueue/demoserver:server_proto",
        "@com_google_protobuf//:any_proto",
        "@com_google_protobuf//java/core",
        "@engflowapis-java//engflow/eventstore/v1",
        "@engflowapis-java//engflow/notification/v1",
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
