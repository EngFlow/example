load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary", "swift_test")

swift_binary(
    name = "swift",
    srcs = ["main.swift"],
)

swift_test(
    name = "MyTests",
    srcs = ["swfit_test.swift"],
    # features = ["-swift.bundled_xctests"],
)