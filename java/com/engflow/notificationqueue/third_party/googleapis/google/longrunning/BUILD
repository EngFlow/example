package(default_applicable_licenses = ["//:license"])

load("@grpc_java//:java_grpc_library.bzl", "java_grpc_library")

proto_library(
    name = "operations_proto",
    srcs = [
        "operations.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//google/api:annotations_proto",
        "//google/api:client_proto",
        "//google/rpc:status_proto",
        "@com_google_protobuf//:any_proto",
        "@com_google_protobuf//:descriptor_proto",
        "@com_google_protobuf//:duration_proto",
        "@com_google_protobuf//:empty_proto",
    ],
)

alias(
    name = "operations_go_proto",
    actual = "@//third_party/go/google.golang.org/genproto/googleapis/longrunning",
    visibility = ["//visibility:public"],
)

java_proto_library(
    name = "operations_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":operations_proto",
    ],
)

java_grpc_library(
    name = "operations_grpc_java_proto",
    srcs = [
        ":operations_proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":operations_java_proto",
    ],
)
