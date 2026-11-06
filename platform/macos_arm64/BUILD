load("@apple_support//xcode:available_xcodes.bzl", "available_xcodes")
load("@apple_support//xcode:xcode_config.bzl", "xcode_config")
load("@apple_support//xcode:xcode_version.bzl", "xcode_version")

package(default_visibility = ["//visibility:public"])

# The platform definition for a remote mac worker.
platform(
    name = "macos_arm64",
    constraint_values = [
        "@platforms//os:macos",
        "@platforms//cpu:arm64",
    ],
    exec_properties = {
        "Pool": "macos_arm_m2",
        "sandboxAllowed": "False",  # ios builds need to escape the sandbox in order to correctly reach XCode.
    },
)

# The XCode installed on the remote worker.
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

xcode_version(
    name = "version27_2_0_27B52",
    aliases = [
        "27.2.0",
        "27.2.0.27B52",
        "27B52",
        "27.2",
        "27",
    ],
    default_ios_sdk_version = "27.2",
    default_macos_sdk_version = "27.2",
    default_tvos_sdk_version = "27.2",
    default_visionos_sdk_version = "27.2",
    default_watchos_sdk_version = "27.2",
    version = "27.2.0.27B52",
)

xcode_config(
    name = "installed_xcodes",
    default = ":version26_5_0_17F42",
    versions = [
        ":version26_5_0_17F42",
        ":version27_2_0_27B52",
    ],
)

available_xcodes(
    name = "available_xcodes",
    default = ":version26_5_0_17F42",
    versions = [
        ":version26_5_0_17F42",
        ":version27_2_0_27B52",
    ],
)
