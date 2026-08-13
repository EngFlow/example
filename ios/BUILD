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

# Non-exclusive leases: concurrent tests may share one simulator. Sharing is
# opportunistic, not bounded — a request only joins a device that is already
# active, so tests dispatched simultaneously can still each get their own.
ios_xctestrun_runner(
    name = "ios_shared_simulator_runner",
    clean_up_simulator_action = "//tools/simulator_manager:release_simulator",
    create_simulator_action = "//tools/simulator_manager:lease_simulator",
    random = False,
    reuse_simulator = True,
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

# Same source, but leasing non-exclusively: several concurrent runs should
# collapse onto fewer devices. Measured on a 16 GiB worker, 8 runs shared 2
# simulators.
ios_unit_test(
    name = "HelloSharedSimulatorTest",
    minimum_os_version = "26.0",
    runner = ":ios_shared_simulator_runner",
    tags = ["manual"],
    timeout = "long",
    deps = [":HelloConcurrentTestLib"],
)

swift_library(
    name = "HelloDyingHostTestLib",
    testonly = True,
    srcs = ["HelloDyingHostTest.swift"],
    module_name = "HelloDyingHostTest",
)

# Kills its own test host to check whether that alone produces the
# "doesn't have a simulator leased" warning. Hosted, so the lease is held by the
# rules_apple runner script rather than the test host -- see the test source.
#
#     bazel test --config=ios --config=opal --config=remote_macos_arm64 \
#       --test_env=SIMULATOR_MANAGER_DEATH_MODE=signal //ios:HelloDyingHostTest
ios_unit_test(
    name = "HelloDyingHostTest",
    minimum_os_version = "26.0",
    runner = ":ios_leased_simulator_runner",
    tags = ["manual"],
    test_host = ":HelloApp",
    deps = [":HelloDyingHostTestLib"],
    exec_properties = {
        "sandboxAllowed": "False",
    },
)

swift_library(
    name = "HelloLongRunningTestLib",
    testonly = True,
    srcs = ["HelloLongRunningTest.swift"],
    module_name = "HelloLongRunningTest",
)

ios_unit_test(
    name = "HelloLongRunningTest",
    minimum_os_version = "26.0",
    runner = ":ios_leased_simulator_runner",
    test_host = ":HelloApp",
    timeout = "long",
    deps = [":HelloLongRunningTestLib"],
    exec_properties = {
        "sandboxAllowed": "False",
    },
)

swift_library(
    name = "HelloHostedSnapshotTestLib",
    testonly = True,
    srcs = ["HelloHostedSnapshotTest.swift"],
    module_name = "HelloHostedSnapshotTest",
)

# Hosted so rules_apple drives it with `xcodebuild -destination id=`, and leasing
# exclusively so each concurrent action gets its own device.
# Run with a high --runs_per_test to put more concurrent actions on a worker than it has
# simulators:
#
#     bazel test --config=ios --config=opal --config=remote_macos_arm64 \
#       --runs_per_test=8 //ios:HelloHostedSnapshotTest
#
# Manual for the same reason as HelloConcurrentTest: sensitive to worker memory.
ios_unit_test(
    name = "HelloHostedSnapshotTest",
    minimum_os_version = "26.0",
    runner = ":ios_leased_simulator_runner",
    tags = ["manual"],
    test_host = ":HelloApp",
    timeout = "long",
    deps = [":HelloHostedSnapshotTestLib"],
    exec_properties = {
        "sandboxAllowed": "False",
    },
)

