"""
deps.bzl contains macros that declare dependencies for each langauge
that needs them.
"""

def go_dependencies():
    """Declares Go dependencies needed by this workspace.

    Managed with 'bazel run //:gazelle -- update-repos -from-file=go.mod.

    Keep in sync with go.mod.
    """
    pass
