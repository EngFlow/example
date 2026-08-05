load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_swift//swift:swift.bzl", "swift_binary", "swift_library", "swift_test")

# A daemon that hands out leases on iOS simulators. Ported from
# https://github.com/bazelbuild/rules_apple/pull/2767, which builds it with an
# internal `macos_swift_tool` macro; a swift_library plus swift_binary is
# equivalent, and lets the tests link the library.
swift_binary(
    name = "simulator_manager",
    srcs = glob(["Sources/*.swift"]),
    tags = ["no-linux-ci"],
    deps = [
        "@swiftpkg_shellout//:ShellOut",
        "@swiftpkg_swift_argument_parser//:ArgumentParser",
        "@swiftpkg_swift_nio//:NIO",
        "@swiftpkg_swift_nio//:NIOCore",
        "@swiftpkg_swift_nio//:NIOHTTP1",
        "@swiftpkg_swift_nio//:NIOPosix",
        "@swiftpkg_swift_nio_extras//:NIOExtras",
    ],
)

# Compiles the daemon's sources directly rather than depending on the binary
# above: linking a swift_binary into a swift_test duplicates `_main`. Main.swift
# is excluded for the same reason.
swift_test(
    name = "simulator_manager_test",
    srcs = glob(["Tests/*.swift"]) + glob(
        ["Sources/*.swift"],
        exclude = ["Sources/Main.swift"],
    ),
    module_name = "simulator_manager",
    tags = ["no-linux-ci"],
    deps = [
        "@swiftpkg_shellout//:ShellOut",
        "@swiftpkg_swift_argument_parser//:ArgumentParser",
        "@swiftpkg_swift_nio//:NIO",
        "@swiftpkg_swift_nio//:NIOCore",
        "@swiftpkg_swift_nio//:NIOHTTP1",
        "@swiftpkg_swift_nio//:NIOPosix",
        "@swiftpkg_swift_nio_extras//:NIOExtras",
    ],
)

sh_binary(
    name = "start",
    srcs = ["start.sh"],
    data = [
        ":prepare_simulator",
        ":simulator_manager",
    ],
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

sh_binary(
    name = "prepare_simulator",
    srcs = ["prepare_simulator.sh"],
)

# rules_apple's create/clean_up_simulator_action hooks. Using these instead of
# patching the runner template (as PR 2767 does) keeps rules_apple unmodified.
sh_binary(
    name = "lease_simulator",
    srcs = ["lease_simulator.sh"],
    data = [":start"],
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

sh_binary(
    name = "release_simulator",
    srcs = ["release_simulator.sh"],
    visibility = ["//visibility:public"],
)
