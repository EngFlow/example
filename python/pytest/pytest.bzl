"""Support for Pytest tests."""

load("@rules_python//python:defs.bzl", "py_test")

def pytest_test(name, srcs = [], deps = [], args = [], **kwargs):
    pytest_args = [
        # Disable Pytest's own caching.
        "-p",
        "no:cacheprovider",
        # Generate the XML summary where Bazel expects it.
        "--junit-xml=$$XML_OUTPUT_FILE",
        # Print the captured output of all tests, so Bazel's --test_output works as expected.
        "-rA",
        # Avoid collecting tests automatically; use what's in `srcs`.
        "--ignore=.",
    ] + [
        "$(location %s)" % src
        for src in srcs
    ] + args

    py_test(
        name = name,
        srcs = srcs + ["//python/pytest:pytest_runner"],
        main = "pytest_runner.py",
        deps = deps + ["//python/pytest:pytest_runner"],
        args = pytest_args,
        **kwargs
    )
