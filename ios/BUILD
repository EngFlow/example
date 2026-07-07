load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_apple//apple:ios.bzl", "ios_application", "ios_ui_test", "ios_unit_test")
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "HelloAppLibrary",
    srcs = ["HelloApp.swift"],
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
)

ios_unit_test(
    name = "HelloTest",
    minimum_os_version = "26.0",
    deps = [":HelloTestLib"],
)

swift_library(
    name = "HelloAppUITestLib",
    testonly = True,
    srcs = [
        "HelloAppUITest.swift",
    ],
    module_name = "HelloAppUITest",
)

ios_ui_test(
    name = "HelloAppUITest",
    minimum_os_version = "26.0",
    runner = "@rules_apple//apple/testing/default_runner:ios_xctestrun_ordered_runner",
    tags = [
        "no-remote-ci",  # Investigating permissions error.
    ],
    test_host = ":HelloApp",
    deps = [":HelloAppUITestLib"],
)
