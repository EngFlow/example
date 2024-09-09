"""Exports the @io_bazel_rules_scala_config repo"""

load("@io_bazel_rules_scala//:scala_config.bzl", _scala_config = "scala_config")

def _scala_config_impl(module_ctx):
    _scala_config()
    return module_ctx.extension_metadata(
        root_module_direct_deps="all",
        root_module_direct_dev_deps=[],
    )

scala_config = module_extension(
    implementation = _scala_config_impl
)
