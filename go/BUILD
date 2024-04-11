load("@rules_go//go:def.bzl", "go_binary", "go_library")

go_binary(
    name = "go",
    embed = [":go_lib"],
    visibility = ["//visibility:public"],
)

go_library(
    name = "go_lib",
    srcs = ["main.go"],
    importpath = "github.com/EngFlow/example/go",
    visibility = ["//visibility:private"],
)
