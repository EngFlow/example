load("@grpc-java//:java_grpc_library.bzl", "java_grpc_library")
load("@rules_java//java:java_binary.bzl", "java_binary")

package(default_visibility = ["//visibility:public"])

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
        "@engflowapis-java//engflow/eventstore/v1",
        "@engflowapis-java//engflow/notification/v1",
        "@grpc-java//api",
        "@grpc-java//context",
        "@grpc-java//netty",
        "@grpc-java//stub",
        "@maven//:com_google_code_findbugs_jsr305",
        "@maven//:com_google_guava_guava",
        "@maven//:commons_cli_commons_cli",
        "@maven//:io_netty_netty_handler",
        "@protobuf//:any_proto",
        "@protobuf//java/core",
    ],
)
