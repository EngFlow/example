package(default_applicable_licenses = ["//:license"])

load("@//third_party/grpc-web/bazel:defs.bzl", "closure_grpc_web_library")
load("@//third_party/rules_closure/closure:defs.bzl", "closure_proto_library")
load("@grpc_java//:java_grpc_library.bzl", "java_grpc_library")

proto_library(
    name = "bytestream_proto",
    srcs = [
        "bytestream.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//google/api:annotations_proto",
        "@com_google_protobuf//:wrappers_proto",
    ],
)

closure_proto_library(
    name = "bytestream_closure_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":bytestream_proto",
    ],
)

alias(
    name = "bytestream_go_proto",
    actual = "@//third_party/go/google.golang.org/genproto/googleapis/bytestream",
    visibility = ["//visibility:public"],
)

java_proto_library(
    name = "bytestream_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":bytestream_proto",
    ],
)

closure_grpc_web_library(
    name = "bytestream_closure_grpc_web_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":bytestream_proto",
    ],
)

java_grpc_library(
    name = "bytestream_grpc_java_proto",
    srcs = [
        ":bytestream_proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":bytestream_java_proto",
    ],
)
