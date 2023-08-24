load("@rules_cc//cc:defs.bzl", "cc_toolchain", "cc_toolchain_suite")

# windows_cc_toolchain_config.bzl is copied from Bazel 7.0.0-pre.20230530.3.
# Specifically copied from the builtin repo
# @local_config_cc//:windows_cc_toolchain_config.bzl.
load(":windows_cc_toolchain_config.bzl", "cc_toolchain_config")

package(default_visibility = ["//visibility:public"])

platform(
    name = "windows_amd64",
    constraint_values = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
        "@io_bazel_rules_go//go/toolchain:cgo_off",
        "@io_bazel_rules_dotnet//dotnet/toolchain:6.0.101",
    ],
    exec_properties = {
        "Pool": "windows",
    },
)

# toolchain is the entry point. --crosstool_top should point here.
# Each key in the toolchains dict is a "cpu|compiler" pair.
# Each value is a cc_toolchain target.
cc_toolchain_suite(
    name = "toolchain",
    tags = ["manual"],
    toolchains = {
        "x64_windows|gcc": ":gcc_cc_toolchain",
        "x64_windows|clang": ":clang_cc_toolchain",
        "x64_windows": ":clang_cc_toolchain",
    },
)

cc_toolchain(
    name = "gcc_cc_toolchain",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 0,
    tags = ["manual"],
    toolchain_config = ":gcc_cc_toolchain_config",
    toolchain_identifier = "gcc",
)

cc_toolchain_config(
    name = "gcc_cc_toolchain_config",
    abi_libc_version = "local",
    abi_version = "local",
    compiler = "gcc",
    cpu = "x64_windows",
    # Obtained by running inside msys2 bash:
    #   echo | /ucrt64/bin/gcc -xc++ -E -v -
    cxx_builtin_include_directories = [
        "C:/msys64/ucrt64/include/c++/13.1.0",
        "C:/msys64/ucrt64/include/c++/13.1.0/x86_64-w64-mingw32",
        "C:/msys64/ucrt64/include/c++/13.1.0/backward",
        "C:/msys64/ucrt64/lib/gcc/x86_64-w64-mingw32/13.1.0/include",
        "C:/msys64/ucrt64/include",
        "C:/msys64/ucrt64/lib/gcc/x86_64-w64-mingw32/13.1.0/include-fixed",
    ],
    host_system_name = "local",
    tags = ["manual"],
    target_libc = "ucrt",
    target_system_name = "local",
    tool_bin_path = "c:/msys64/ucrt64/bin",
    tool_paths = {
        "ar": "c:/msys64/ucrt64/bin/ar.exe",
        "cpp": "c:/msys64/ucrt64/bin/cpp.exe",
        "dwp": "c:/msys64/ucrt64/bin/dwp.exe",
        "gcc": "c:/msys64/ucrt64/bin/gcc.exe",
        "gcov": "c:/msys64/ucrt64/bin/gcov.exe",
        "ld": "c:/msys64/ucrt64/bin/ld.exe",
        "nm": "c:/msys64/ucrt64/bin/nm.exe",
        "objcopy": "c:/msys64/ucrt64/bin/objcopy.exe",
        "objdump": "c:/msys64/ucrt64/bin/objdump.exe",
        "strip": "c:/msys64/ucrt64/bin/strip.exe",
    },
)

cc_toolchain(
    name = "clang_cc_toolchain",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 0,
    tags = ["manual"],
    toolchain_config = ":clang_cc_toolchain_config",
    toolchain_identifier = "clang",
)

cc_toolchain_config(
    name = "clang_cc_toolchain_config",
    abi_libc_version = "local",
    abi_version = "local",
    compiler = "clang",
    cpu = "x64_windows",
    # Obtained by running inside msys2 bash:
    #   echo | /ucrt64/bin/clang -xc++ -E -v -
    cxx_builtin_include_directories = [
        "C:/msys64/ucrt64/include/c++/13.1.0",
        "C:/msys64/ucrt64/include/c++/13.1.0/x86_64-w64-mingw32",
        "C:/msys64/ucrt64/include/c++/13.1.0/backward",
        "C:/msys64/ucrt64/lib/clang/16/include",
        "C:/msys64/ucrt64/include",
    ],
    host_system_name = "local",
    tags = ["manual"],
    target_libc = "ucrt",
    target_system_name = "local",
    tool_bin_path = "c:/msys64/ucrt64/bin",
    tool_paths = {
        "ar": "c:/msys64/ucrt64/bin/ar.exe",
        "cpp": "c:/msys64/ucrt64/bin/cpp.exe",
        "dwp": "c:/msys64/ucrt64/bin/dwp.exe",
        "gcc": "c:/msys64/ucrt64/bin/clang.exe",
        "gcov": "c:/msys64/ucrt64/bin/gcov.exe",
        "ld": "c:/msys64/ucrt64/bin/ld.exe",
        "nm": "c:/msys64/ucrt64/bin/nm.exe",
        "objcopy": "c:/msys64/ucrt64/bin/objcopy.exe",
        "objdump": "c:/msys64/ucrt64/bin/objdump.exe",
        "strip": "c:/msys64/ucrt64/bin/strip.exe",
    },
)

filegroup(
    name = "empty",
)
