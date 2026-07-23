# Copied BUILD and cc_toolchain_config.bzl from `bazel info output_base`/external/apple_support++apple_cc_configure_extension+local_config_apple_cc/
# Cleaned up by:
# - Running buildifier
# - Fixing paths in cxx_builtin_include_directories

package(default_visibility = ["//visibility:public"])

load("@rules_cc//cc:defs.bzl", "cc_library", "cc_toolchain", "cc_toolchain_suite")
load("@apple_support//configs:platforms.bzl", "APPLE_PLATFORMS_CONSTRAINTS")
load(":cc_toolchain_config.bzl", "cc_toolchain_config")

_APPLE_ARCHS = APPLE_PLATFORMS_CONSTRAINTS.keys()

CC_TOOLCHAINS = [(
    cpu + "|clang",
    ":cc-compiler-" + cpu,
) for cpu in _APPLE_ARCHS] + [(
    cpu,
    ":cc-compiler-" + cpu,
) for cpu in _APPLE_ARCHS] + [
    ("k8|clang", ":cc-compiler-darwin_x86_64"),
    ("darwin|clang", ":cc-compiler-darwin_x86_64"),
    ("k8", ":cc-compiler-darwin_x86_64"),
    ("darwin", ":cc-compiler-darwin_x86_64"),
]

cc_library(
    name = "link_extra_lib",
)

cc_library(
    name = "malloc",
)

filegroup(
    name = "empty",
    srcs = [],
)

cc_toolchain_suite(
    name = "toolchain",
    toolchains = dict(CC_TOOLCHAINS),
)

filegroup(
    name = "modulemap",
    srcs = [
"@apple_support//crosstool:exec_layering_check_modulemap",
    ],
)

filegroup(
    name = "tools",
    srcs = [
        "@apple_support//crosstool:exec_libtool",
        "@apple_support//crosstool:exec_wrapped_clang",
        "@apple_support//crosstool:exec_wrapped_clang_pp",
        ":modulemap",
    ],
)

[
    cc_toolchain(
        name = "cc-compiler-" + arch,
        all_files = ":tools",
        ar_files = ":tools",
        as_files = ":tools",
        compiler_files = ":tools",
        dwp_files = ":empty",
        linker_files = ":tools",
        objcopy_files = ":empty",
        strip_files = ":tools",
        supports_header_parsing = 1,
        supports_param_files = 1,
        toolchain_config = arch,
        toolchain_identifier = arch,
        module_map = "@apple_support//crosstool:module.modulemap",
    )
    for arch in _APPLE_ARCHS
]

[
    cc_toolchain_config(
        name = arch,
        cpu = arch,
        features = [
            "no_warn_duplicate_libraries",
            "reproducible_linker_flag",
        ],
        cxx_builtin_include_directories = [
            "/Applications/",
            "/Library/",
            "/Applications/engflow/xcode-snap-08701857f4029532c/Xcode.app/Contents/Developer/Library/",
        ],
        libtool = "@apple_support//crosstool:exec_libtool",
        tool_paths_overrides = {},
        c_flags = [],
        conly_flags = [],
        cxx_flags = ["-std=c++17"],
        link_flags = [],
        module_map = ":modulemap",
        wrapped_clang = "@apple_support//crosstool:exec_wrapped_clang",
        wrapped_clang_pp = "@apple_support//crosstool:exec_wrapped_clang_pp",
    )
    for arch in _APPLE_ARCHS
]
