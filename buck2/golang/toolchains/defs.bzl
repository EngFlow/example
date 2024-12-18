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

load("@prelude//go:toolchain.bzl", "GoToolchainInfo")
load("@prelude//go_bootstrap:go_bootstrap.bzl", "GoBootstrapToolchainInfo")
load("@prelude//utils:cmd_script.bzl", "ScriptOs", "cmd_script")

def _remote_go_bootstrap_toolchain_impl(ctx):
    go_arch = "amd64"  
    go_os = "linux"

    script_os = ScriptOs("unix")
    go = "go"

    return [
        DefaultInfo(),
        GoBootstrapToolchainInfo(
            env_go_arch = go_arch,
            env_go_os = go_os,
            go = RunInfo(cmd_script(ctx, "go", cmd_args(go), script_os)),
            go_wrapper = ctx.attrs.go_wrapper[RunInfo],
        ),
    ]

remote_go_bootstrap_toolchain = rule(
    impl = _remote_go_bootstrap_toolchain_impl,
    doc = """Example remote go toolchain rules. Usage:
  remote_go_bootstrap_toolchain(
      name = "go_bootstrap",
      visibility = ["PUBLIC"],
  )""",
    attrs = {
        "go_wrapper": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//go/tools:go_wrapper_py")),
    },
    is_toolchain_rule = True,
)

def _remote_go_toolchain_impl(ctx):
    go_arch = "amd64"  
    go_os = "linux"

    script_os = ScriptOs("unix")
    go = "go"

    return [
        DefaultInfo(),
        GoToolchainInfo(
            assembler = RunInfo(cmd_script(ctx, "asm", cmd_args(go, "tool", "asm"), script_os)),
            cgo = RunInfo(cmd_script(ctx, "cgo", cmd_args(go, "tool", "cgo"), script_os)),
            cgo_wrapper = ctx.attrs.cgo_wrapper[RunInfo],
            concat_files = ctx.attrs.concat_files[RunInfo],
            compiler = RunInfo(cmd_script(ctx, "compile", cmd_args(go, "tool", "compile"), script_os)),
            cover = RunInfo(cmd_script(ctx, "cover", cmd_args(go, "tool", "cover"), script_os)),
            default_cgo_enabled = False,
            env_go_arch = go_arch,
            env_go_os = go_os,
            external_linker_flags = [],
            gen_stdlib_importcfg = ctx.attrs.gen_stdlib_importcfg[RunInfo],
            go = RunInfo(cmd_script(ctx, "go", cmd_args(go), script_os)),
            go_wrapper = ctx.attrs.go_wrapper[RunInfo],
            linker = RunInfo(cmd_script(ctx, "link", cmd_args(go, "tool", "link"), script_os)),
            packer = RunInfo(cmd_script(ctx, "pack", cmd_args(go, "tool", "pack"), script_os)),
            linker_flags = [],
            assembler_flags = [],
            compiler_flags = [],
        ),
    ]
   

remote_go_toolchain = rule(
    impl = _remote_go_toolchain_impl,
    doc = """Example remote go toolchain rules. Usage:
  remote_go_toolchain(
      name = "go",
      visibility = ["PUBLIC"],
  )""",
    attrs = {
        "cgo_wrapper": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//go/tools:cgo_wrapper")),
        "concat_files": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//go_bootstrap/tools:go_concat_files")),
        "gen_stdlib_importcfg": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//go/tools:gen_stdlib_importcfg")),
        "go_wrapper": attrs.default_only(attrs.dep(providers = [RunInfo], default = "prelude//go_bootstrap/tools:go_go_wrapper")),
    },
    is_toolchain_rule = True,
)
