load("@rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "resourceusage_lib",
    srcs = ["resourceusage.go"],
    importpath = "github.com/EngFlow/example/go/resourceusage",
    visibility = ["//visibility:private"],
    deps = [
        "@engflowapis-go//engflow/notification/v1",
        "@engflowapis-go//engflow/resourceusage/v1",
        "@org_golang_google_grpc//:grpc",
        "@org_golang_google_grpc//codes",
        "@org_golang_google_grpc//credentials",
        "@org_golang_google_grpc//status",
    ],
)

go_binary(
    name = "resourceusage",
    embed = [":resourceusage_lib"],
    visibility = ["//visibility:public"],
)
