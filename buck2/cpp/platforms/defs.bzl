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

# This platform is essentially the same as the one provided in https://github.com/facebook/buck2/blob/804d62242214455d51787f7c8c96a1e12c75ec32/examples/remote_execution/engflow/platforms/defs.bzl
# The main difference is we enable passing CPU and OS constraints and we use the sample EngFlow RE image.
load("@prelude//:build_mode.bzl", "BuildModeInfo")

def _platforms(ctx):
    constraints = dict()
    constraints.update(ctx.attrs.cpu_configuration[ConfigurationInfo].constraints)
    constraints.update(ctx.attrs.os_configuration[ConfigurationInfo].constraints)
    configuration = ConfigurationInfo(
        constraints = constraints,
        values = {},
    )

    # The sample EngFlow RE image.
    image = "docker://gcr.io/bazel-public/ubuntu2004-java11@sha256:69a78f121230c6d5cbfe2f4af8ce65481aa3f2acaaaf8e899df335f1ac1b35b5"
    name = ctx.label.raw_target()
    platform = ExecutionPlatformInfo(
        label = ctx.label.raw_target(),
        configuration = configuration,
        executor_config = CommandExecutorConfig(
            local_enabled = False,
            remote_enabled = True,
            use_limited_hybrid = False,
            remote_execution_properties = {
                "container-image": image,
            },
            remote_execution_use_case = "buck2-default",
            # TODO: Use output_paths
            remote_output_paths = "strict",
        ),
    )

    return [
        DefaultInfo(),
        ExecutionPlatformRegistrationInfo(platforms = [platform]),
        configuration,
        PlatformInfo(label = str(name), configuration = configuration),
    ]

def _action_keys(ctx):
    return [
        DefaultInfo(),
        BuildModeInfo(cell = ctx.attrs.cell, mode = ctx.attrs.mode),
    ]

platforms = rule(
    attrs = {
        "cpu_configuration": attrs.dep(providers = [ConfigurationInfo]),
        "os_configuration": attrs.dep(providers = [ConfigurationInfo]),
    }, 
    impl = _platforms
)

action_keys = rule(
     attrs = {
        "cell": attrs.string(),
        "mode": attrs.string(),
     },
     impl = _action_keys
)
