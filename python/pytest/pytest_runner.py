"""Bazel adapter for Pytest."""

import os
import sys

import pytest


if __name__ == "__main__":
    extra_args = []

    # Support `shard_count` on test targets.
    test_total_shards = os.environ.get("TEST_TOTAL_SHARDS")
    test_shard_index = os.environ.get("TEST_SHARD_INDEX")
    if test_total_shards:
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
