load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")
load("//python/pytest:pytest.bzl", "pytest_test")

py_library(
    name = "hello",
    srcs = ["hello.py"],
)

py_binary(
    name = "python",
    srcs = ["main.py"],
    main = "main.py",
    deps = [":hello"],
)

# Supports sharding, fast-failing and test filtering out of the box: try
#   bazel test //python:hello_absl_test --test_filter="HelloTest.test_hello" --test_output=all
# `--test_filter` values are as in https://docs.python.org/3/library/unittest.html#cmdoption-unittest-k
py_test(
    name = "hello_absl_test",
    srcs = ["hello_absl_test.py"],
    shard_count = 2,
    deps = [
        ":hello",
        "@io_abseil_py//absl/testing:absltest",
    ],
    size = "small",
)

# This wrapper supports sharding, fast-failing and test filtering: try
#   bazel test //python:hello_pytest_test --test_filter="not test_hello" --test_output=all
# This corresponds to Pytest's `-k` flag: see https://docs.pytest.org/en/latest/reference/reference.html#command-line-flags
pytest_test(
    name = "hello_pytest_test",
    srcs = ["hello_pytest_test.py"],
    shard_count = 2,
    tags = ["todo-pe1188-remote-incompatible"],
    deps = [":hello"],
    size = "small",
)

py_test(
    name = "hello_unittest_test",
    srcs = ["hello_unittest_test.py"],
    deps = [":hello"],
    size = "small",
)

# Utility to help re-generate requirements lock.
#
# Validate: bazel test //python:requirements_test
# Update: bazel run //python:requirements.update
compile_pip_requirements(
    name = "requirements",
    requirements_in = "requirements.txt",
    requirements_txt = "requirements_lock.txt",
    tags = ["manual"],
)
