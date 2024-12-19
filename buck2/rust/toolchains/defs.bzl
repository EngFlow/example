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

load("@prelude//rust:rust_toolchain.bzl", "PanicRuntime", "RustToolchainInfo")
load("@prelude//rust/tools:attrs.bzl", "internal_tool_attrs")
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

def _remote_rust_toolchain_impl(ctx):    
    return [
        DefaultInfo(),
        RustToolchainInfo(
            allow_lints = ctx.attrs.allow_lints,
            clippy_driver = RunInfo(args = [ctx.attrs.clippy_driver]),
            clippy_toml = ctx.attrs.clippy_toml[DefaultInfo].default_outputs[0] if ctx.attrs.clippy_toml else None,
            compiler = RunInfo(args = [ctx.attrs.compiler]),
            default_edition = ctx.attrs.default_edition,
            panic_runtime = PanicRuntime("unwind"),
            deny_lints = ctx.attrs.deny_lints,
            doctests = ctx.attrs.doctests,
            failure_filter_action = ctx.attrs.failure_filter_action[RunInfo],
            nightly_features = ctx.attrs.nightly_features,
            report_unused_deps = ctx.attrs.report_unused_deps,
            rustc_action = ctx.attrs.rustc_action[RunInfo],
            rustc_binary_flags = ctx.attrs.rustc_binary_flags,
            rustc_flags = ctx.attrs.rustc_flags,
            rustc_target_triple = ctx.attrs.rustc_target_triple,
            rustc_test_flags = ctx.attrs.rustc_test_flags,
            rustdoc = RunInfo(args = [ctx.attrs.rustdoc]),
            rustdoc_flags = ctx.attrs.rustdoc_flags,
            rustdoc_test_with_resources = ctx.attrs.rustdoc_test_with_resources[RunInfo],
            rustdoc_coverage = ctx.attrs.rustdoc_coverage[RunInfo],
            transitive_dependency_symlinks_tool = ctx.attrs.transitive_dependency_symlinks_tool[RunInfo],
            warn_lints = ctx.attrs.warn_lints,
        ),
    ]

remote_rust_toolchain = rule(
    impl = _remote_rust_toolchain_impl,
    attrs = internal_tool_attrs | {
        "allow_lints": attrs.list(attrs.string(), default = []),
        "clippy_driver": attrs.string(default = "clippy-driver"),
        "clippy_toml": attrs.option(attrs.dep(providers = [DefaultInfo]), default = None),
        "compiler": attrs.string(default = "rustc"),
        "default_edition": attrs.option(attrs.string(), default = None),
        "deny_lints": attrs.list(attrs.string(), default = []),
        "doctests": attrs.bool(default = False),
        "nightly_features": attrs.bool(default = False),
        "report_unused_deps": attrs.bool(default = False),
        "rustc_binary_flags": attrs.list(attrs.string(), default = []),
        "rustc_flags": attrs.list(attrs.string(), default = []),
        "rustc_target_triple": attrs.string(default = "x86_64-unknown-linux-gnu"),
        "rustc_test_flags": attrs.list(attrs.string(), default = []),
        "rustdoc": attrs.string(default = "rustdoc"),
        "rustdoc_flags": attrs.list(attrs.string(), default = []),
        "warn_lints": attrs.list(attrs.string(), default = []),
    },
    is_toolchain_rule = True,
)
