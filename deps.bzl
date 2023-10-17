"""
deps.bzl contains macros that declare dependencies for each langauge
that needs them.
"""

load("@bazel_gazelle//:deps.bzl", "go_repository")

def go_dependencies():
    """Declares Go dependencies needed by this workspace.

    Managed with 'bazel run //:gazelle -- update-repos -from-file=go.mod.

    Keep in sync with go.mod.
    """
    go_repository(
        name = "com_github_google_go_cmp",
        importpath = "github.com/google/go-cmp",
        sum = "h1:ofyhxvXcZhMsU5ulbFiLKl/XBFqE1GSq7atu8tAmTRI=",
        version = "v0.6.0",
    )
