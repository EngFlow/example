package(default_applicable_licenses = ["//:license"])

proto_library(
    name = "annotations_proto",
    srcs = [
        "annotations.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":http_proto",
        "@com_google_protobuf//:descriptor_proto",
    ],
)

alias(
    name = "annotations_go_proto",
    actual = "@//third_party/go/google.golang.org/genproto/googleapis/api/annotations",
    visibility = ["//visibility:public"],
)

proto_library(
    name = "client_proto",
    srcs = [
        "client.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "@com_google_protobuf//:descriptor_proto",
    ],
)

alias(
    name = "client_go_proto",
    actual = "@//third_party/go/google.golang.org/genproto/googleapis/api/annotations",
    visibility = ["//visibility:public"],
)

proto_library(
    name = "field_behavior_proto",
    srcs = [
        "field_behavior.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "@com_google_protobuf//:descriptor_proto",
    ],
)

alias(
    name = "field_behavior_go_proto",
    actual = "@//third_party/go/google.golang.org/genproto/googleapis/api/annotations",
    visibility = ["//visibility:public"],
)

proto_library(
    name = "http_proto",
    srcs = [
        "http.proto",
    ],
    visibility = ["//visibility:public"],
)

alias(
    name = "http_go_proto",
    actual = "@//third_party/go/google.golang.org/genproto/googleapis/api/annotations",
    visibility = ["//visibility:public"],
)

proto_library(
    name = "label_proto",
    srcs = [
        "label.proto",
    ],
    visibility = ["//visibility:public"],
)

proto_library(
    name = "launch_stage_proto",
    srcs = [
        "launch_stage.proto",
    ],
    visibility = ["//visibility:public"],
)

proto_library(
    name = "monitored_resource_proto",
    srcs = [
        "monitored_resource.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":label_proto",
        ":launch_stage_proto",
        "@com_google_protobuf//:struct_proto",
    ],
)

java_proto_library(
    name = "monitored_resource_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":monitored_resource_proto",
    ],
)
