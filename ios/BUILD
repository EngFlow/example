load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_apple//apple:ios.bzl", "ios_application", "ios_ui_test", "ios_unit_test")
load(
    "@rules_apple//apple/testing/default_runner:ios_xctestrun_runner.bzl",
    "ios_xctestrun_runner",
)
load("@rules_swift//swift:swift.bzl", "swift_library")

# Leases each test its own simulator from //tools/simulator_manager, so
# concurrent actions on one worker never share a device.
ios_xctestrun_runner(
    name = "ios_leased_simulator_runner",
    clean_up_simulator_action = "//tools/simulator_manager:release_simulator",
    create_simulator_action = "//tools/simulator_manager:lease_simulator",
    random = False,
    # reuse_simulator doubles as the exclusivity toggle for the lease: opting out
    # of reuse means no other test shares this device.
    reuse_simulator = False,
)

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
    runner = ":ios_leased_simulator_runner",
    test_host = ":HelloApp",
    deps = [":HelloAppUITestLib"],
    exec_properties = {
        "sandboxAllowed": "False",
    },
)

swift_library(
    name = "HelloConcurrentTestLib",
    testonly = True,
    srcs = ["HelloConcurrentTest.swift"],
    module_name = "HelloConcurrentTest",
)

# Exercises concurrent leasing: run with --runs_per_test to get several
# simultaneous leases from one target. Unlike HelloAppUITest this has no test
# host, so it takes rules_apple's `simctl spawn` path rather than `xcodebuild`.
#
#     bazel test --config=ios --runs_per_test=3 //ios:HelloConcurrentTest
#
# Each run's log reports its simulator UDID; no two concurrent runs should match.
# Manual because it is sensitive to how much memory the host has — see the
# simulator_manager README.
ios_unit_test(
    name = "HelloConcurrentTest",
    minimum_os_version = "26.0",
    runner = ":ios_leased_simulator_runner",
    tags = ["manual"],
    timeout = "long",
    deps = [":HelloConcurrentTestLib"],
)

