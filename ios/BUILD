load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_apple//apple:ios.bzl", "ios_application", "ios_ui_test", "ios_unit_test", "ios_xctestrun_runner")
load("@rules_idb//idb:idb_test_runner.bzl", "ios_idb_test_runner")
load("@rules_swift//swift:swift.bzl", "swift_library")

# Define testrunners for ios tests.

## Default testrunner supplied by rules_apple.
ios_xctestrun_runner(
    name = "legacy_runner",
    device_type = "iPhone 16 Pro",
)

## Testrunner based on idb.
ios_idb_test_runner(
    name = "idb_runner",
    device_type = "iPhone 16 Pro",
)

# Actual sample targets and tests.

swift_library(
    name = "HelloAppLibrary",
    srcs = ["HelloApp.swift"],
    tags = ["manual"],
)

ios_application(
    name = "HelloApp",
    bundle_id = "com.engflow.helloapp",
    families = [
        "iphone",
        "ipad",
    ],
    minimum_os_version = "26.0",
    deps = [":HelloAppLibrary"],
)

build_test(
    name = "HelloApp_build_test",
    targets = [
        ":HelloApp",
    ],
)

swift_library(
    name = "HelloTestLib",
    testonly = True,
    srcs = ["HelloTest.swift"],
    tags = ["manual"],
)

ios_unit_test(
    name = "HelloTest",
    minimum_os_version = "26.0",
    runner = ":legacy_runner",
    deps = [":HelloTestLib"],
)

swift_library(
    name = "HelloAppUITestLib",
    testonly = True,
    srcs = [
        "HelloAppUITest.swift",
    ],
    module_name = "HelloAppUITest",
    tags = ["manual"],
)

ios_ui_test(
    name = "HelloAppUITest",
    minimum_os_version = "26.0",
    runner = ":legacy_runner",
    test_host = ":HelloApp",
    deps = [":HelloAppUITestLib"],
)

ios_ui_test(
    name = "HelloAppUITest_idb",
    minimum_os_version = "26.0",
    runner = ":idb_runner",
    test_host = ":HelloApp",
    deps = [":HelloAppUITestLib"],
)
