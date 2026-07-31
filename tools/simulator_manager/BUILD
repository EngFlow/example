load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_swift//swift:swift.bzl", "swift_binary", "swift_test")

# A daemon that hands out leases on iOS simulators. Ported from
# https://github.com/bazelbuild/rules_apple/pull/2767, which builds it with an
# internal `macos_swift_tool` macro; a plain swift_binary is equivalent here.
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

swift_test(
    name = "simulator_manager_test",
    srcs = glob(["Tests/*.swift"]),
    tags = ["no-linux-ci"],
    deps = [":simulator_manager"],
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
