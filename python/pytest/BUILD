load("@pip//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_library")

py_library(
    name = "pytest_runner",
    srcs = ["pytest_runner.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("pytest"),
        requirement("pytest-shard"),
    ],
)
