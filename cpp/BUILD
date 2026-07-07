load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

cc_binary(
    name = "cpp",
    srcs = ["main.cc"],
    deps = [":cpp_lib"],
)

cc_library(
    name = "cpp_lib",
    srcs = [
        "hello.cc",
        "hello.h",
    ],
)

build_test(
    name = "cpp_build_test",
    targets = [
        ":cpp",
    ],
)

cc_test(
    name = "cpp_test",
    size = "small",
    srcs = ["hello_test.cc"],
    deps = [":cpp_lib"],
)
