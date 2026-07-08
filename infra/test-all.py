#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys

EXTRA_FLAGS = {
    "ios": ["--config=ios"],
    "swift": ["--config=clang"],
}


def report_error(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)


def validate_env():
    for key in ("ARCH", "OS", "EXECUTION_TYPE", "OPAL_RPC_CREDENTIALS"):
        if not os.getenv(key):
            report_error(f"{key} not set")


def find_tests(package):
    os_name = os.getenv("OS")
    remote = os.getenv("EXECUTION_type")

    # Remove tests based on tags and environment
    query = f"""
    let t = tests(//{package}/...) in
    $t - 
    attr(tags, no-ci, $t) - 
    attr(tags, no-{os_name}-ci, $t) - 
    attr(tags, no-{remote}-ci, $t)
    """.strip()

    print(f"Executing query to find test targets:\n{query}")
    args = ["bazel", "query", "--output=label", "--", query]
    result = subprocess.run(args, capture_output=True)
    output = result.stdout.decode()
    return [t for t in output.split("\n") if t]


def run_tests(package):
    targets = find_tests(package)
    if not targets:
        print(f"No targets found for {package}, skipping.")
        return 0
    print(f"Executing tests {targets}")

    os_arch = os.getenv("OS") + "_" + os.getenv("ARCH")
    flags = ["--config=ci"]
    if os.getenv("EXECUTION_TYPE") == "remote":
        flags += [
            "--config=remote_" + os_arch,
            "--config=opal",
        ]
    else:
        flags += [
            "--config=opal_bes",
            "--config=opal_auth",
        ]

    if package in EXTRA_FLAGS:
        flags += EXTRA_FLAGS[package]

    print(f"---------------\nTesting {package}...")
    sys.stdout.flush()

    args = ["bazel", "test"] + flags + ["--"] + targets
    result = subprocess.run(args, check=False)
    sys.stdout.flush()
    sys.stderr.flush()
    return result.returncode


def main():
    parser = argparse.ArgumentParser(
        description="Runs example test suites", fromfile_prefix_chars="@"
    )
    parser.add_argument(
        "--package",
        required=False,
        help="Package to test.",
    )
    parser.add_argument(
        "--validate-env",
        action=argparse.BooleanOptionalAction,
        help="Whether to validate environment variables",
    )
    opts = parser.parse_args()

    if opts.validate_env:
        validate_env()

    package = opts.package

    returncode = run_tests(opts.package)
    if returncode != 0:
        sys.exit(returncode)


if __name__ == "__main__":
    main()
