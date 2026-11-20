"""Vendored Swift explicit module repos for the remote macOS workers.

This mirrors the `configure_xcode` mode of rules_swift's `system_sdk`
extension, but generates a separate `@vendored_system_sdk` hub repo so that
local builds keep using rules_swift's auto-detected `@system_sdk`. The hub is
only used by the toolchains in this package, which are registered by
`--config=remote_macos_arm64`.
"""

load(
    "@rules_swift//tools/explicit_modules:precomputed_xcode_explicit_module_repo.bzl",
    "precomputed_xcode_explicit_module_repo",
)
load(
    "@rules_swift//tools/explicit_modules:xcode_explicit_module_hub_repo.bzl",
    "xcode_explicit_module_hub_repo",
)

def _sanitize(v):
    return v.replace(".", "_").replace("-", "_")

def _vendored_system_sdk_impl(module_ctx):
    versions = []
    default_manifest = None
    for mod in module_ctx.modules:
        for tag in mod.tags.configure_xcode:
            if tag.version in versions:
                fail("Duplicate configure_xcode() for Xcode version '{}'.".format(tag.version))
            versions.append(tag.version)

            # The hub repo refers to these repos as `@system_sdk_xcode_<version>`.
            repo_name = "system_sdk_xcode_" + _sanitize(tag.version)
            precomputed_xcode_explicit_module_repo(
                name = repo_name,
                xcode_version = tag.version,
                build_file = tag.build_file,
            )
            if default_manifest == None:
                default_manifest = "@{}//:module_names.json".format(repo_name)

    if not versions:
        fail("At least one configure_xcode() tag is required.")

    xcode_explicit_module_hub_repo(
        name = "vendored_system_sdk",
        xcode_versions = versions,
        default_manifest = default_manifest,
    )

    return module_ctx.extension_metadata(reproducible = True)

vendored_system_sdk = module_extension(
    implementation = _vendored_system_sdk_impl,
    tag_classes = {
        "configure_xcode": tag_class(
            attrs = {
                "build_file": attr.label(
                    mandatory = True,
                    allow_single_file = True,
                    doc = "Explicit module BUILD for the given Xcode.",
                ),
                "version": attr.string(
                    mandatory = True,
                    doc = "Canonical Xcode version string (e.g. 26.5.0.17F42).",
                ),
            },
        ),
    },
    doc = "Generate @vendored_system_sdk from vendored explicit module BUILD files.",
)
