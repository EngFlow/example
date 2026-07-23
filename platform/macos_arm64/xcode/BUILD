# Copied from `bazel info output_base`/external/bazel_tools+xcode_configure_extension+local_config_xcode/BUILD
# Cleaned up by:
# - Removing XCodes installed locally but not on the cluster
# - Renaming `host_` to `installed_`
# - Reformatting and running buildifier

load("@apple_support//xcode:available_xcodes.bzl", "available_xcodes")
load("@apple_support//xcode:xcode_config.bzl", "xcode_config")
load("@apple_support//xcode:xcode_version.bzl", "xcode_version")

package(default_visibility = ["//visibility:public"])

xcode_version(
    name = "version26_5_0_17F42",
    aliases = [
        "26.5.0",
        "26.5",
        "17F42",
        "26.5.0.17F42",
        "26",
    ],
    default_ios_sdk_version = "26.5",
    default_macos_sdk_version = "26.5",
    default_tvos_sdk_version = "26.5",
    default_visionos_sdk_version = "26.5",
    default_watchos_sdk_version = "26.5",
    version = "26.5.0.17F42",
)

xcode_config(
    name = "installed_xcodes",
    default = ":version26_5_0_17F42",
    versions = [":version26_5_0_17F42"],
)

available_xcodes(
    name = "installed_available_xcodes",
    default = ":version26_5_0_17F42",
    versions = [":version26_5_0_17F42"],
)
