package(default_visibility = ["//visibility:public"])

platform(
    name = "macos_x64",
    constraint_values = [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
        "@io_bazel_rules_go//go/toolchain:cgo_off",
        "@io_bazel_rules_dotnet//dotnet/toolchain:6.0.101",
    ],
    exec_properties = {
        "Pool": "macos_x64",
    },
)
