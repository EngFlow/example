load("@bazel_skylib//rules:build_test.bzl", "build_test")
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

build_test(
    name = "go_build_test",
    targets = [
        ":go",
    ],
)
