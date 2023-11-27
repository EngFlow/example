# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This becomes the BUILD file for @local_config_cc// under Windows.

load("@rules_cc//cc:defs.bzl", "cc_toolchain", "cc_toolchain_suite", "cc_library")
load(":windows_cc_toolchain_config.bzl", "cc_toolchain_config")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "malloc",
)

filegroup(
    name = "empty",
    srcs = [],
)

filegroup(
    name = "mingw_compiler_files",
    srcs = [":builtin_include_directory_paths_mingw"]
)

filegroup(
    name = "clangcl_compiler_files",
    srcs = [":builtin_include_directory_paths_clangcl"]
)

filegroup(
    name = "msvc_compiler_files",
    srcs = [":builtin_include_directory_paths_msvc"]
)

platform(
    name = "windows_x64_clang",
    constraint_values = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
        "@bazel_tools//tools/cpp:clang-cl",
        "@io_bazel_rules_go//go/toolchain:cgo_off",
        "@io_bazel_rules_dotnet//dotnet/toolchain:6.0.101",
    ],
    exec_properties = {
        "container-image": "docker://645088952840.dkr.ecr.eu-west-1.amazonaws.com/engflow-re/windows-x64:engflow_worker@sha256:eb56698f9b9a8005e4f1bad9b5ae61791c6d384c3503cb7f52cf6dcb70cf5e31",
        "Pool": "windows",
        #"container-image": "docker://eu.gcr.io/engflow-re-oss/engflow-re/windows-x64@sha256:eb56698f9b9a8005e4f1bad9b5ae61791c6d384c3503cb7f52cf6dcb70cf5e31"
    },
)

platform(
    name = "windows_x64_msys",
    constraint_values = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
        "@bazel_tools//tools/cpp:msys",
        "@io_bazel_rules_go//go/toolchain:cgo_off",
        "@io_bazel_rules_dotnet//dotnet/toolchain:6.0.101",
    ],
    exec_properties = {
        "container-image": "docker://645088952840.dkr.ecr.eu-west-1.amazonaws.com/engflow-re/windows-x64:engflow_worker@sha256:eb56698f9b9a8005e4f1bad9b5ae61791c6d384c3503cb7f52cf6dcb70cf5e31",
        "Pool": "windows",
        #"container-image": "docker://eu.gcr.io/engflow-re-oss/engflow-re/windows-x64@sha256:eb56698f9b9a8005e4f1bad9b5ae61791c6d384c3503cb7f52cf6dcb70cf5e31"
    },
)


platform(
    name = "windows_x64_mingw",
    constraint_values = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
        "@bazel_tools//tools/cpp:mingw",
        "@io_bazel_rules_go//go/toolchain:cgo_off",
        "@io_bazel_rules_dotnet//dotnet/toolchain:6.0.101",
    ],
    exec_properties = {
        "container-image": "docker://645088952840.dkr.ecr.eu-west-1.amazonaws.com/engflow-re/windows-x64:engflow_worker@sha256:eb56698f9b9a8005e4f1bad9b5ae61791c6d384c3503cb7f52cf6dcb70cf5e31",
        "Pool": "windows",
        #"container-image": "docker://eu.gcr.io/engflow-re-oss/engflow-re/windows-x64@sha256:eb56698f9b9a8005e4f1bad9b5ae61791c6d384c3503cb7f52cf6dcb70cf5e31"
    },
)

platform(
    name = "windows_x64_msvc",
    constraint_values = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
        "@bazel_tools//tools/cpp:msvc",
        "@io_bazel_rules_go//go/toolchain:cgo_off",
        "@io_bazel_rules_dotnet//dotnet/toolchain:6.0.101",
    ],
    exec_properties = {
        "container-image": "docker://645088952840.dkr.ecr.eu-west-1.amazonaws.com/engflow-re/windows-x64:engflow_worker@sha256:eb56698f9b9a8005e4f1bad9b5ae61791c6d384c3503cb7f52cf6dcb70cf5e31",
        "Pool": "windows",
        #"container-image": "docker://eu.gcr.io/engflow-re-oss/engflow-re/windows-x64@sha256:eb56698f9b9a8005e4f1bad9b5ae61791c6d384c3503cb7f52cf6dcb70cf5e31"
    },
)

toolchain(
    name = "cc-toolchain-x64_windows",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:windows",
        "@bazel_tools//tools/cpp:msvc",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:windows",
        "@bazel_tools//tools/cpp:msvc",
    ],
    toolchain = ":cc-compiler-x64_windows",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

toolchain(
    name = "cc-toolchain-x64_windows-clang-cl",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:windows",
        "@bazel_tools//tools/cpp:clang-cl",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:windows",
        "@bazel_tools//tools/cpp:clang-cl",
    ],
    toolchain = ":cc-compiler-x64_windows-clang-cl",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

toolchain(
    name = "cc-toolchain-x64_windows_msys",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:windows",
        "@bazel_tools//tools/cpp:msys",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:windows",
        "@bazel_tools//tools/cpp:msys",
    ],
    toolchain = ":cc-compiler-x64_windows_msys",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

# Hardcoded toolchain, legacy behaviour.
cc_toolchain_suite(
    name = "toolchain",
    toolchains = {
        "x64_windows|msvc": ":cc-compiler-x64_windows",
        "x64_windows|gcc": ":cc-compiler-x64_windows_msys",
        "x64_windows|mingw-gcc": ":cc-compiler-x64_windows_mingw",
        "x64_windows|clang": ":cc-compiler-x64_windows-clang-cl",
        "x64_windows": ":cc-compiler-x64_windows",
    },
)

cc_toolchain(
    name = "cc-compiler-x64_windows_msys",
    toolchain_identifier = "gcc",
    toolchain_config = ":msys_x64",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":mingw_compiler_files",
    compiler_files = ":mingw_compiler_files",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
)

cc_toolchain_config(
    name = "msys_x64",
    cpu = "x64_windows",
    compiler = "gcc",
    host_system_name = "local",
    target_system_name = "local",
    target_libc = "ucrt",
    abi_version = "local",
    abi_libc_version = "local",
    cxx_builtin_include_directories = [         
        "C:/msys64/ucrt64/include/c++/13.2.0",
        "C:/msys64/ucrt64/include/c++/13.2.0/x86_64-w64-mingw32",
        "C:/msys64/ucrt64/include/c++/13.2.0/backward",
        "C:/msys64/ucrt64/lib/gcc/x86_64-w64-mingw32/13.2.0/include",
        "C:/msys64/ucrt64/include",
        "C:/msys64/ucrt64/lib/gcc/x86_64-w64-mingw32/13.2.0/include-fixed",
    ],
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
    tool_bin_path = "c:/msys64/ucrt64/bin",
    dbg_mode_debug_flag = "/DEBUG:FULL",
    fastbuild_mode_debug_flag = "/DEBUG:FASTLINK",
    toolchain_identifier = "gcc",
)

cc_toolchain(
    name = "cc-compiler-x64_windows_mingw",
    toolchain_identifier = "msys_x64_mingw",
    toolchain_config = ":msys_x64_mingw",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":mingw_compiler_files",
    compiler_files = ":mingw_compiler_files",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 0,
)

cc_toolchain_config(
    name = "msys_x64_mingw",
    cpu = "x64_windows",
    compiler = "mingw-gcc",
    host_system_name = "local",
    target_system_name = "local",
    target_libc = "mingw",
    abi_version = "local",
    abi_libc_version = "local",
    tool_bin_path = "c:/msys64/mingw64/bin",
    cxx_builtin_include_directories = [
        "C:/msys64/mingw64/include/c++/13.2.0",
        "C:/msys64/mingw64/include/c++/13.2.0/x86_64-w64-mingw32",
        "C:/msys64/mingw64/include/c++/13.2.0/backward",
        "C:/msys64/mingw64/lib/gcc/x86_64-w64-mingw32/13.2.0/include",
        "C:/msys64/mingw64/include",
        "C:/msys64/mingw64/lib/gcc/x86_64-w64-mingw32/13.2.0/include-fixed",
    ],
    tool_paths = {
        "ar": "c:/msys64/mingw64/bin/ar.exe",
        "cpp": "c:/msys64/mingw64/bin/cpp.exe",
        "dwp": "c:/msys64/mingw64/bin/dwp.exe",
        "gcc": "c:/msys64/mingw64/bin/gcc.exe",
        "gcov": "c:/msys64/mingw64/bin/gcov.exe",
        "ld": "c:/msys64/mingw64/bin/ld.exe",
        "nm": "c:/msys64/mingw64/bin/nm.exe",
        "objcopy": "c:/msys64/mingw64/bin/objcopy.exe",
        "objdump": "c:/msys64/mingw64/bin/objdump.exe",
        "strip": "c:/msys64/mingw64/bin/strip.exe"},
    dbg_mode_debug_flag = "/DEBUG:FULL",
    fastbuild_mode_debug_flag = "/DEBUG:FASTLINK",
)

toolchain(
    name = "cc-toolchain-x64_windows_mingw",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:windows",
        "@bazel_tools//tools/cpp:mingw",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:windows",
    ],
    toolchain = ":cc-compiler-x64_windows_mingw",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

cc_toolchain(
    name = "cc-compiler-x64_windows",
    toolchain_identifier = "msvc-cl",
    toolchain_config = ":msvc_x64",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":msvc_compiler_files",
    compiler_files = ":msvc_compiler_files",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
)

cc_toolchain_config(
    name = "msvc_x64",
    cpu = "x64_windows",
    compiler = "msvc-cl",
    host_system_name = "local",
    target_system_name = "local",
    target_libc = "msvcrt",
    abi_version = "local",
    abi_libc_version = "local",
    toolchain_identifier = "msvc-cl",
    msvc_env_tmp = "C:\\Windows\\TEMP",
    msvc_env_path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC\\14.29.30133\\bin\\HostX64\\x64;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\VC\\VCPackages;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\CommonExtensions\\Microsoft\\TestWindow;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\MSBuild\\Current\\bin\\Roslyn;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\Tools\\devinit;C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.19041.0\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\bin\\x64;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\\\MSBuild\\Current\\Bin;C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\Tools\\;;C:\\Windows\\system32;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\CommonExtensions\\Microsoft\\CMake\\CMake\\bin;C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\IDE\\CommonExtensions\\Microsoft\\CMake\\Ninja",
    msvc_env_include = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC\\14.29.30133\\include;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\ucrt;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\shared;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\um;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\winrt;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\cppwinrt",
    msvc_env_lib = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC\\14.29.30133\\lib\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\lib\\10.0.19041.0\\ucrt\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\lib\\10.0.19041.0\\um\\x64",      
    msvc_cl_path = "C:/Program Files/engflow/bin/msvc_filter_showincludes.exe",     
    msvc_ml_path = "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/ml64.exe",   
    msvc_link_path = "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/link.exe", 
    msvc_lib_path = "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/bin/HostX64/x64/lib.exe",   
    cxx_builtin_include_directories = [        
        "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC\\14.29.30133\\include",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\ucrt",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\shared",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\um",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\winrt",
        "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.19041.0\\cppwinrt"
        ],
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
    archiver_flags = ["/MACHINE:X64"],
    default_link_flags = ["/MACHINE:X64"],
    dbg_mode_debug_flag = "/DEBUG:FULL",
    fastbuild_mode_debug_flag = "/DEBUG:FASTLINK",
    supports_parse_showincludes = True,
)




cc_toolchain(
    name = "cc-compiler-x64_windows-clang-cl",
    toolchain_identifier = "clang_cl",
    toolchain_config = ":clang_cl_x64",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":clangcl_compiler_files",
    compiler_files = ":clangcl_compiler_files",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
)

cc_toolchain_config(
    name = "clang_cl_x64",
    cpu = "x64_windows",
    compiler = "clang-cl",
    host_system_name = "local",
    target_system_name = "local",
    target_libc = "mingw",
    abi_version = "local",
    abi_libc_version = "local",
    toolchain_identifier = "clang_cl",
    tool_bin_path = "c:/msys64/ucrt64/bin",
    cxx_builtin_include_directories = [
        "C:/msys64/ucrt64/include/c++/13.2.0",
        "C:/msys64/ucrt64/include/c++/13.2.0/x86_64-w64-mingw32",
        "C:/msys64/ucrt64/include/c++/13.2.0/backward",
        "C:/msys64/ucrt64/lib/gcc/x86_64-w64-mingw32/13.2.0/include",
        "C:/msys64/ucrt64/include",
        "C:/msys64/ucrt64/lib/gcc/x86_64-w64-mingw32/13.2.0/include-fixed",
    ],
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
    archiver_flags = ["/MACHINE:X64"],
    default_link_flags = ["/MACHINE:X64", "/DEFAULTLIB:clang_rt.builtins-x86_64.lib"],
    dbg_mode_debug_flag = "/DEBUG",
    fastbuild_mode_debug_flag = "/DEBUG",
    supports_parse_showincludes = False,
)


