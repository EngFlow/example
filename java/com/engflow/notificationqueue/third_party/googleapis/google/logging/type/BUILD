proto_library(
    name = "http_request_proto",
    srcs = [
        "http_request.proto",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "@com_google_protobuf//:duration_proto",
    ],
)

java_proto_library(
    name = "http_request_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":http_request_proto",
    ],
)

proto_library(
    name = "log_severity_proto",
    srcs = [
        "log_severity.proto",
    ],
    visibility = ["//visibility:public"],
)

java_proto_library(
    name = "log_severity_java_proto",
    visibility = ["//visibility:public"],
    deps = [
        ":log_severity_proto",
    ],
)
