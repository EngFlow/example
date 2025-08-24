"""Bazel adapter for Pytest."""

import os
import pathlib
import sys

import pytest


if __name__ == "__main__":
    extra_args = []

    # Support `shard_count` on test targets.
    test_total_shards = os.environ.get("TEST_TOTAL_SHARDS")
    test_shard_index = os.environ.get("TEST_SHARD_INDEX")
    test_shard_status_file = os.environ.get("TEST_SHARD_STATUS_FILE")
    if test_total_shards:
        if test_shard_status_file:
            pathlib.Path(test_shard_status_file).touch()
        extra_args.extend(
            [
                "--num-shards",
                test_total_shards,
                "--shard-id",
                test_shard_index,
            ]
        )

    # Support `--test_filter` on the command line.
    test_filter = os.environ.get("TESTBRIDGE_TEST_ONLY")
    if test_filter:
        extra_args.extend(["-k", test_filter])

    # Support `--test_runner_fail_fast` on the command line.
    fail_fast = os.environ.get("TESTBRIDGE_TEST_RUNNER_FAIL_FAST")
    if fail_fast:
        extra_args.extend(["--maxfail=1"])

    exit_code = pytest.main(sys.argv + extra_args)
    if exit_code == pytest.ExitCode.NO_TESTS_COLLECTED:
        # Pytest usually fails when no tests are found, but we accept this for
        # sharded tests or with user-specified filters.
        if test_total_shards:
            print(
                "WARNING: No tests found for this shard. Consider reducing "
                "the shard_count on your test target.",
                file=sys.stderr,
            )
            sys.exit(pytest.ExitCode.OK)
    sys.exit(exit_code)
