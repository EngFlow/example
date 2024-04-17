load(":windows_cc_toolchain_config.bzl", "cc_toolchain_config")
load("@rules_cc//cc:defs.bzl", "cc_toolchain", "cc_toolchain_suite")

package(default_visibility = ["//visibility:public"])

platform(
    name = "windows_x64",
    constraint_values = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
        "@bazel_tools//tools/cpp:msvc",
        "@rules_go//go/toolchain:cgo_off",
    ],
    exec_properties = {
        "container-image": "docker://645088952840.dkr.ecr.eu-west-1.amazonaws.com/engflow-re/windows-x64:engflow_worker@sha256:6a53c6d5cbc82ca0782e9117482e457a676920227b697de5db90ff53e7afedbe",
        "Pool": "windows",
    },
)

toolchain(
    name = "cc-toolchain",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
        "@bazel_tools//tools/cpp:msvc",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
        "@bazel_tools//tools/cpp:msvc",
    ],
    toolchain = ":msvc_cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

cc_toolchain_suite(
    name = "toolchain",
    toolchains = {
        "x64_windows|msvc": ":msvc_cc_toolchain",
        "x64_windows": ":msvc_cc_toolchain",
    },
)

cc_toolchain(
    name = "msvc_cc_toolchain",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
    toolchain_config = ":msvc_cc_toolchain_config",
    toolchain_identifier = "msvc-cl",
)

cc_toolchain_config(
    name = "msvc_cc_toolchain_config",
    abi_libc_version = "local",
    abi_version = "local",
    archiver_flags = ["/MACHINE:X64"],
    compiler = "msvc-cl",
    cpu = "x64_windows",
    cxx_builtin_include_directories = [
        "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC\\14.29.30133\\include",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\ucrt",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\shared",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\um",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\winrt",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\cppwinrt",
    ],
    dbg_mode_debug_flag = "/DEBUG:FULL",
    default_link_flags = ["/MACHINE:X64"],
    fastbuild_mode_debug_flag = "/DEBUG:FASTLINK",
    host_system_name = "local",
    msvc_cl_path = "C:/Program Files/engflow/bin/msvc_filter_showincludes.exe",
    msvc_env_include = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC\\14.29.30133\\include;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\ucrt;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\shared;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\um;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\winrt;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\cppwinrt",
    msvc_env_lib = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC\\14.29.30133\\lib\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\lib\\10.0.19041.0\\ucrt\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\lib\\10.0.19041.0\\um\\x64",
    msvc_env_path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC\\14.29.30133\\bin\\HostX64\\x64;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\VC\\VCPackages;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\CommonExtensions\\Microsoft\\TestWindow;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\MSBuild\\Current\\bin\\Roslyn;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\Tools\\devinit;C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.19041.0\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\bin\\x64;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\\\MSBuild\\Current\\Bin;C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\Tools\\;;C:\\Windows\\system32;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\CommonExtensions\\Microsoft\\CMake\\CMake\\bin;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\CommonExtensions\\Microsoft\\CMake\\Ninja",
    msvc_env_tmp = "C:\\Windows\\TEMP",
    msvc_lib_path = "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/lib.exe",
    msvc_link_path = "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/link.exe",
    msvc_ml_path = "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/ml64.exe",
    target_libc = "msvcrt",
    target_system_name = "local",
    tool_paths = {
        "ar": "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/lib.exe",
        "ml": "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/ml64.exe",
        "cpp": "C:/Program Files/engflow/bin/msvc_filter_showincludes.exe",
        "gcc": "C:/Program Files/engflow/bin/msvc_filter_showincludes.exe",
        "gcov": "wrapper/bin/msvc_nop.bat",
        "ld": "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/link.exe",
        "nm": "wrapper/bin/msvc_nop.bat",
        "objcopy": "wrapper/bin/msvc_nop.bat",
        "objdump": "wrapper/bin/msvc_nop.bat",
        "strip": "wrapper/bin/msvc_nop.bat",
    },
    toolchain_identifier = "msvc-cl",
)

filegroup(
    name = "empty",
)
