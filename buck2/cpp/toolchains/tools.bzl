# Copyright 2022 EngFlow Inc. All rights reserved.
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

load("@prelude//cxx:cxx_toolchain_types.bzl", "LinkerType")
load("@prelude//toolchains:cxx.bzl", "CxxToolsInfo")

# This def is similar to the one in https://github.com/facebook/buck2/blob/804d62242214455d51787f7c8c96a1e12c75ec32/prelude/toolchains/cxx/clang/tools.bzl
# The main difference is we set linker to "g++" to match the cpp tools installed in the sample docker container.
def _path_clang_tools_impl(_ctx) -> list[Provider]:
    return [
        DefaultInfo(),
        CxxToolsInfo(
            compiler = "clang",
            compiler_type = "clang",
            cxx_compiler = "clang++",
            asm_compiler = "clang",
            asm_compiler_type = "clang",
            rc_compiler = None,
            cvtres_compiler = None,
            archiver = "ar",
            archiver_type = "gnu",
            linker = "g++",
            linker_type = LinkerType("gnu"),
        ),
    ]

path_clang_tools = rule(
    impl = _path_clang_tools_impl,
    attrs = {},
)
