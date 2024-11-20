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

load(
    "@prelude//:artifacts.bzl",
    "ArtifactGroupInfo",
)
load(
    "@prelude//python:toolchain.bzl",
    "PythonPlatformInfo",
    "PythonToolchainInfo",
)

def _remote_python_toolchain_impl(ctx):
    """
    A very simple toolchain that is hardcoded to use python3.
    """

    return [
        DefaultInfo(),
        PythonToolchainInfo(
            binary_linker_flags = [],
            linker_flags = [],
            fail_with_message = ctx.attrs._fail_with_message[RunInfo],
            generate_static_extension_info = ctx.attrs._generate_static_extension_info,
            make_source_db = ctx.attrs._make_source_db[RunInfo],
            make_source_db_no_deps = ctx.attrs._make_source_db_no_deps[RunInfo],
            host_interpreter = RunInfo(args = ["python3"]),
            interpreter = RunInfo(args = ["python3"]),
            make_py_package_modules = ctx.attrs._make_py_package_modules[RunInfo],
            make_py_package_inplace = ctx.attrs._make_py_package_inplace[RunInfo],
            compile = RunInfo(args = ["echo", "COMPILEINFO"]),
            package_style = "inplace",
            pex_extension = ".pex",
            native_link_strategy = "separate",
            runtime_library = ctx.attrs._runtime_library,
        ),
        PythonPlatformInfo(name = "x86_64"),
    ]

remote_python_toolchain = rule(
    impl = _remote_python_toolchain_impl,
    attrs = {
        "_fail_with_message": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//python/tools:fail_with_message")),
        "_generate_static_extension_info": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//python/tools:generate_static_extension_info")),
        "_make_py_package_inplace": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//python/tools:make_py_package_inplace")),
        "_make_py_package_modules": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//python/tools:make_py_package_modules")),
        "_make_source_db": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//python/tools:make_source_db")),
        "_make_source_db_no_deps": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//python/tools:make_source_db_no_deps")),
        "_runtime_library": attrs.default_only(attrs.dep(providers = [ArtifactGroupInfo], default = "prelude//python/runtime:bootstrap_files")),

    },
    is_toolchain_rule = True,
)
