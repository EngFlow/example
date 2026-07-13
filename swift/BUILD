load("@rules_swift//swift:swift.bzl", "swift_test")

swift_test(
    name = "swift_test",
    size = "small",
    srcs = [
        "example.swift",
        #"main.swift",
    ],
    tags = [
        "no-linux-ci",  # No linux swift toolchains currently defined.
    ],
)
