package(default_visibility = ["//visibility:public"])

load("@io_grpc_grpc_java//:java_grpc_library.bzl", "java_grpc_library")

proto_library(
    name = "server_proto",
    srcs = ["server.proto"],
)

java_proto_library(
    name = "server_java_proto",
    deps = [":server_proto"],
)

java_grpc_library(
    name = "server_java_grpc_proto",
    srcs = [
        ":server_proto",
    ],
    deps = [
        ":server_java_proto",
    ],
)

java_binary(
    name = "server",
    srcs = [
        "DemoServer.java",
    ],
    main_class = "com.engflow.notificationqueue.demoserver.DemoServer",
    deps = [
        ":server_java_grpc_proto",
        ":server_java_proto",
        ":server_proto",
        "@io_grpc_grpc_java//api",
        "@io_grpc_grpc_java//netty",
        "@io_grpc_grpc_java//stub",
    ],
)
