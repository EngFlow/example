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

"""Macros and rules for accessing canonical repository names and paths"""

load("@rules_js//js:providers.bzl", "JsInfo", _js_info_provider = "js_info")

# These macros execute during the loading phase. For `alias` targets, they
# return the name of the repo containing the `alias`, not the repo of the
# target from its `actual` attribute.

def canonical_repo(target_label):
    """Return the canonical repository name corresponding to target_label."""
    return Label(target_label).repo_name

def workspace_root(target_label):
    """Return a target's repo workspace path relative to the execroot."""
    return Label(target_label).workspace_root

# These rules will produce the repo name of the target of an `alias` rule,
# defined by its `actual` attribute.

def _variable_info(ctx, value):
    """Return a TemplateVariableInfo provider for Make variable rules."""
    return [platform_common.TemplateVariableInfo({ctx.attr.name: value})]

repo_name_variable = rule(
    implementation = lambda ctx: _variable_info(
        ctx, ctx.attr.dep.label.repo_name
    ),
    doc = "Defines a custom variable for its dependency's repository name",
    attrs = {
        "dep": attr.label(
            mandatory = True,
            doc = "target for which to extract the repository name",
        ),
    },
)

repo_dir_variable = rule(
    implementation = lambda ctx: _variable_info(
        ctx, ctx.attr.dep.label.workspace_root
    ),
    doc = "Defines a custom variable for its dependency's repository dir",
    attrs = {
        "dep": attr.label(
            mandatory = True,
            doc = "target for which to extract the repository dir",
        ),
    },
)

# The following functions implement the `gen_js_constants` rule.

def _js_info(label, sources, deps):
    """Return a JsInfo provider for sources with transitive values from deps."""
    transitive_sources = [sources]
    transitive_types = []
    npm_sources = []
    npm_package_store_infos = []

    for i in [dep[JsInfo] for dep in deps if JsInfo in dep]:
        transitive_sources.append(i.transitive_sources)
        transitive_types.append(i.transitive_types)
        npm_sources.append(i.npm_sources)
        npm_package_store_infos.append(i.npm_package_store_infos)

    return _js_info_provider(
        target = label,
        sources = sources,
        transitive_sources = depset(transitive = transitive_sources),
        transitive_types = depset(transitive = transitive_types),
        npm_sources = depset(transitive = npm_sources),
        npm_package_store_infos = depset(transitive = npm_package_store_infos),
    )

def _runfiles(ctx, sources, deps):
    """Return a ctx.runfiles object with aggregate runfiles from deps."""
    deps_info = [dep[DefaultInfo] for dep in deps]
    runfiles = ctx.runfiles(
        files = sources.to_list(),
        transitive_files = depset(transitive = [i.files for i in deps_info]),
    )
    return runfiles.merge_all([i.default_runfiles for i in deps_info])

def _gen_js_constants_impl(ctx):
    """Generate a JavaScript module exporting specified constants."""
    items  = {"ruleName": ctx.attr.name, "binDir": ctx.bin_dir.path}
    items |= {k: ctx.expand_location(v) for k, v in ctx.attr.vars.items()}
    items |= {v: k.label.repo_name for k, v in ctx.attr.repo_names.items()}
    items |= {v: k.label.workspace_root for k, v in ctx.attr.repo_dirs.items()}
    declaration = "module.exports.{} = \"{}\";"
    constants = [declaration.format(k, v) for k, v in items.items()]

    outfile = ctx.actions.declare_file(ctx.attr.name + ".js")
    ctx.actions.write(outfile, "\n".join(constants) + "\n")

    sources = depset([outfile])
    deps = ctx.attr.deps + \
        ctx.attr.repo_names.keys() + \
        ctx.attr.repo_dirs.keys()

    return [
        _js_info(ctx.label, sources, deps),
        DefaultInfo(files = sources, runfiles = _runfiles(ctx, sources, deps)),
    ]

gen_js_constants = rule(
    implementation = _gen_js_constants_impl,
    doc = "Generate a JavaScript module exporting specified constants.",
    attrs = {
        "deps": attr.label_list(
            doc = "target labels for predefined source/output path variables",
        ),
        "vars": attr.string_dict(
            doc = "mapping from constants to values or source/output vars",
        ),
        "repo_names": attr.label_keyed_string_dict(
            doc = "mapping from target label to generated repo name constant",
        ),
        "repo_dirs": attr.label_keyed_string_dict(
            doc = "mapping from target label to generated repo dir constant",
        ),
    },
)
