package(default_applicable_licenses = ["//:license"])

load("@grpc_java//:java_grpc_library.bzl", "java_grpc_library")

proto_library(
    name = "build_proto",
    srcs = [
        "build_events.proto",
        "build_status.proto",
        "publish_build_event.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//google/api:annotations_proto",
        "//google/api:client_proto",
        "//google/api:field_behavior_proto",
        "@com_google_protobuf//:any_proto",
        "@com_google_protobuf//:duration_proto",
        "@com_google_protobuf//:empty_proto",
        "@com_google_protobuf//:timestamp_proto",
        "@com_google_protobuf//:wrappers_proto",
    ],
)

java_proto_library(
    name = "build_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":build_proto",
    ],
)

java_grpc_library(
    name = "build_grpc_java_proto",
    srcs = [
        ":build_proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":build_java_proto",
    ],
)
