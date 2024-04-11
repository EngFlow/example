load("@pip//:requirements.bzl", "requirement")

py_library(
    name = "pytest_runner",
    srcs = ["pytest_runner.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("pytest"),
        requirement("pytest-shard"),
    ],
)
