# Copyright 2024 EngFlow Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

load(
    "//:repo-names.bzl",
    "canonical_repo",
    "workspace_root",
    "repo_name_variable",
    "repo_dir_variable",
    "gen_js_constants",
)
load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
load("@rules_js//js:defs.bzl", "js_binary")

# This value propagates through the rules below.
# Try it with other targets of your choosing!
repo_target = "@pnpm"

# The following value inspired the `repo_name_variable` rule.
# - A macro executes during the loading phase and doesn't see resolved aliases.
# - A rule executes during the analysis phase, after aliases have resolved.
#repo_target = "@bison_v3.3.2//bin:bison"

# Demonstrates the macro-based approach.
genrule(
    name = "repo-macros",
    outs = ["repo-macros.txt"],
    cmd = "printf '%s\n  canonical_name: %s\n  workspace_root: %s\n' >$@" % (
      repo_target, canonical_repo(repo_target), workspace_root(repo_target)
    )
)

# Demonstrates the custom Make variable-based approach. Depends on the
# ":repo-target" alias to show how the variables have access to the underlying
# target.
genrule(
    name = "repo-vars",
    outs = ["repo-vars.txt"],
    cmd = r"""printf '%%s\n' \
          '%s' \
          '  repo-name: $(repo-name)' \
          '  repo-dir:  $(repo-dir)' >$@""" % repo_target,
    toolchains = [
        ":repo-name",
        ":repo-dir",
    ]
)

# This alias demonstrates how the rules from `repo-names.bzl` work with resolved
# aliases during the analysis phase. Calling the `canonical_repo()` and
# `workspace_root()` macros with ":repo-target" in this file will return the
# empty string, since macros execute during the loading phase.
alias(
    name = "repo-target",
    actual = repo_target,
)

# These rules create custom variables that other rules can use by adding
# ":repo-name" and ":repo-dir" to their `toolchains` attribute.
# - https://bazel.build/reference/be/make-variables#custom_variables
# - https://bazel.build/rules/lib/providers/TemplateVariableInfo
repo_name_variable(
    name = "repo-name",
    dep = ":repo-target",
)

repo_dir_variable(
    name = "repo-dir",
    dep = ":repo-target",
)

# Run this program via the following commands for different values of
# `repo_target` above. `node` must be installed for the invocations outside of
# `bazel run`.
#
# ```txt
# bazel run --//:constants=genrule //:repo-dir-check
# node bazel-bin/repo-dir-check.mjs
#
# bazel run --//:constants=custom //:repo-dir-check
# node bazel-bin/repo-dir-check.mjs
# ```
#
# Note the differences between:
# - the macro-generated repo dir and the variable- or rule-generated repo dir
# - where the repo dir is found when running under `bazel run` vs `node`
js_binary(
    name = "repo-dir-check",
    entry_point = "repo-dir-check.mjs",
    data = [
      ":constants-impl",
      repo_target,
    ],
)

# Determines which rule generates the `constants.js` module used by
# `:repo-dir-check`, based on the value of the `--//:constants` flag.
genrule(
    name = "constants-impl",
    outs = ["constants.js"],
    srcs = select({
        ":genrule":     [":genrule-constants"],
        ":custom-rule": [":custom-rule-constants"],
    }),
    cmd = "cp $< $@",
)

# The `--//:constants` command line flag determines whether `:constants-impl`
# selects `:genrule-constants` or `:custom-rule-constants` as input.
string_flag(
    name = "constants",
    values = [
        "genrule",
        "custom-rule",
    ],
    build_setting_default = "genrule",
)

config_setting(
    name = "genrule",
    flag_values = {":constants": "genrule"},
)

config_setting(
    name = "custom-rule",
    flag_values = {":constants": "custom-rule"},
)

# A genrule producing a constants module illustrating how to incorporate:
# - the `BINDIR` predefined Make variable
# - the `rlocationpaths` predefined variable, called on the ":repo-target" alias
# - the `canonical_name()` and `workspace_root()` macros, called during the
#   loading phase on a variable
# - the `repo_name_variable` and `repo_dir_variable` targets, evaluated during
#   the analysis phase, which supplies a custom variable as a `toolchains`
#   attribute target
#
# Replacing `repo_target` with the string ":repo-target" in the macros below
# will produce the empty string, since the macros won't see the resolved alias.
genrule(
    name = "genrule-constants",
    srcs = [":repo-target"],
    outs = ["genrule-constants.js"],
    cmd  = r"""printf 'module.exports.%%s;\n' \
        'ruleName = "genrule-constants"' \
        'target = "%s"' \
        'binDir = "$(BINDIR)"' \
        'location = "$(rlocationpaths :repo-target)"' \
        'macroName = "%s"' \
        'macroDir = "%s"' \
        'repoName = "$(repo-name)"' \
        'repoDir = "$(repo-dir)"' >$@""" % (
            repo_target,
            canonical_repo(repo_target),
            workspace_root(repo_target)
        ),
    toolchains = [
        ":repo-name",
        ":repo-dir",
    ],
)

# A custom rule producing a constants module from its `vars`, `repo_names`, and
# `repo_dirs` attributes.
#
# This rule illustrates how to use:
# - The `rlocationpaths` predefined variable, called on the ":repo-target" alias
# - The `canonical_name()` and `workspace_root()` macros, called during the
#     loading phase on a variable
# - The `repo_names` and `repo_dirs` attributes of type
#   `attr.label_keyed_string_dict`, whose keys are resolved Target values
#   (including aliases) during the analysis phase
#
# Note that:
# - For the `vars` attribute, the keys become constant names, and the values
#   become constant values.
# - For the `repo_names` and `repo_dirs` attributes, the keys become constant
#   values, and the values become constant names.
#
# Replacing `repo_target` with the string ":repo-target" in the macros below
# will produce the empty string, since the macros won't see the resolved alias.
gen_js_constants(
    name  = "custom-rule-constants",
    deps = [":repo-target"],
    vars  = {
        "target":    repo_target,
        "location":  "$(rlocationpaths :repo-target)",
        "macroName": canonical_repo(repo_target),
        "macroDir":  workspace_root(repo_target),
    },
    repo_names = {":repo-target": "repoName"},
    repo_dirs  = {":repo-target": "repoDir"},
)
