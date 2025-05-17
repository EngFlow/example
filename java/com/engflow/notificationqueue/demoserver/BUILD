load("@grpc-java//:java_grpc_library.bzl", "java_grpc_library")
load("@protobuf//bazel:java_proto_library.bzl", "java_proto_library")
load("@protobuf//bazel:proto_library.bzl", "proto_library")
load("@rules_java//java:java_binary.bzl", "java_binary")

package(default_visibility = ["//visibility:public"])

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
        "@grpc-java//api",
        "@grpc-java//netty",
        "@grpc-java//stub",
    ],
)
