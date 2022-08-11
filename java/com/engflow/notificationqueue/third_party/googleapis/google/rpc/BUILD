package(default_applicable_licenses = ["//:license"])

proto_library(
    name = "code_proto",
    srcs = [
        "code.proto",
    ],
    visibility = ["//visibility:public"],
)

alias(
    name = "code_go_proto",
    actual = "@//third_party/go/google.golang.org/genproto/googleapis/rpc/code",
    visibility = ["//visibility:public"],
)

java_proto_library(
    name = "code_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":code_proto",
    ],
)

proto_library(
    name = "error_details_proto",
    srcs = [
        "error_details.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "@com_google_protobuf//:duration_proto",
    ],
)

alias(
    name = "error_details_go_proto",
    actual = "@//third_party/go/google.golang.org/genproto/googleapis/rpc/errdetails",
    visibility = ["//visibility:public"],
)

java_proto_library(
    name = "error_details_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":error_details_proto",
    ],
)

proto_library(
    name = "status_proto",
    srcs = [
        "status.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "@com_google_protobuf//:any_proto",
    ],
)

alias(
    name = "status_go_proto",
    actual = "@//third_party/go/google.golang.org/genproto/googleapis/rpc/status",
    visibility = ["//visibility:public"],
)

java_proto_library(
    name = "status_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":status_proto",
    ],
)
