load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
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
        ":install_post_boot_script",
        ":prepare_simulator",
        ":simulator_manager",
    ],
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

# Copies the post-boot script somewhere that outlives the action. Split out of
# start.sh so it can be tested on its own: the copy only runs on the
# daemon-start path, which is skipped whenever a current daemon is already up.
sh_binary(
    name = "install_post_boot_script",
    srcs = ["install_post_boot_script.sh"],
)

sh_test(
    name = "install_post_boot_script_test",
    srcs = ["install_post_boot_script_test.sh"],
    data = [":install_post_boot_script"],
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

sh_test(
    name = "release_simulator_test",
    srcs = ["release_simulator_test.sh"],
    data = [":release_simulator"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

# Drives a real daemon over a unix socket, so it cannot run in the sandbox and
# must not run concurrently with another copy of itself.
sh_test(
    name = "start_restart_test",
    srcs = ["start_restart_test.sh"],
    data = [
        ":release_simulator",
        ":start",
    ],
    tags = [
        "local",
        "no-linux-ci",
        "no-sandbox",
    ],
    # Each lease provisions and boots a real simulator, and each case deletes the
    # devices it made so the next one cannot adopt them.
    timeout = "long",
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
