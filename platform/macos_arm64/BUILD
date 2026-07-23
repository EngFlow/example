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
        "test.sandboxAllowed": "False",  # ios tests need to escape the sandbox in order to correctly reach the simulator service.
    },
)
