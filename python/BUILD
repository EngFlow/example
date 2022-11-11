"""Example of a python build/test with coverage.
"""

load("@coveragepy//:requirements.bzl", "entry_point")

alias(
    name = "python_coverage_tools",
    actual = entry_point("coverage"),
)

py_library(
    name = "example",
    srcs = [
        "__init__.py",
        "example.py",
    ],
)

py_test(
    name = "test_example",
    size = "small",
    srcs = ["test_example.py"],
    env = {
        # In theory this should be `$(execpath :python_coverage_tool)`,
        #
        # however this will not resolve correctly as Bazel will
        # resolve this relative to the runfiles directory. Instead, we
        # just manually specify the path in the runfiles directory the
        # coverage tools will be placed in.
        #
        # For a better solution involving setting the coverage tool in
        # the toolchain, see
        # https://github.com/bazelbuild/bazel/pull/15590
        "PYTHON_COVERAGE": "coveragepy_coverage/rules_python_wheel_entry_point_coverage",
    },
    deps = [
        ":example",
        ":python_coverage_tools",
    ],
)
