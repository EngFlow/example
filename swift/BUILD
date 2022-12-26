load("@build_bazel_rules_swift//swift:swift.bzl", "swift_test")

swift_test(
    name = "tests",
    srcs = [ "main.swift", "example.swift"],
    env = {
        "XCTEST_ENV_VAR": "TRUE",
        "XCTEST_BINDIR_ENV_VAR": "$(BINDIR)",
    },
)