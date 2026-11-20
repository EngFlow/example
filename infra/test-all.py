#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import uuid

EXTRA_FLAGS = {
    "ios": ["--config=ios"],
    "swift": ["--config=clang"],
}

# Must match --bes_results_url for --config=opal_bes in .bazelrc.
BES_RESULTS_URL = "https://opal.cluster.engflow.com/invocations/example-oss/"


def report_error(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)


def validate_env():
    for key in ("ARCH", "OS", "EXECUTION_TYPE", "OPAL_RPC_CREDENTIALS"):
        if not os.getenv(key):
            report_error(f"{key} not set")


def find_tests(package):
    os_name = os.getenv("OS")
    remote = os.getenv("EXECUTION_TYPE")

    # Remove tests based on tags and environment
    query = f"""
    let t = tests(//{package}/...) in
    $t 
    - attr(tags, no-ci, $t)
    - attr(tags, no-{os_name}-ci, $t)
    - attr(tags, no-{remote}-ci, $t)
    - attr(tags, no-{remote}-{os_name}-ci, $t)
    """.strip()

    print(f"Executing query to find test targets:\n{query}")
    args = ["bazel", "query", "--output=label", "--", query]
    result = subprocess.run(args, capture_output=True)
    output = result.stdout.decode()
    return [t for t in output.split("\n") if t]


def run_tests(package, extra_flags):
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

    flags += extra_flags

    print(f"---------------\nTesting {package}...")
    sys.stdout.flush()

    invocation_id = str(uuid.uuid4())
    flags.append(f"--invocation_id={invocation_id}")

    args = ["bazel", "test"] + flags + ["--"] + targets
    result = subprocess.run(args, check=False)
    sys.stdout.flush()
    sys.stderr.flush()
    report_invocation(package, BES_RESULTS_URL + invocation_id, result.returncode)
    return result.returncode


def report_invocation(package, url, returncode):
    """Surfaces the BES invocation link in the GitHub Actions UI."""
    if not os.getenv("GITHUB_ACTIONS"):
        return

    execution_type = os.getenv("EXECUTION_TYPE")
    status = "passed" if returncode == 0 else "failed"
    level = "notice" if returncode == 0 else "error"
    title = f"{package} ({execution_type}) {status}"

    # Annotation: shown on the run summary page and in the Checks tab.
    print(f"::{level} title={title}::Invocation results: {url}")

    # Job summary: rendered as Markdown on the run summary page.
    summary_file = os.getenv("GITHUB_STEP_SUMMARY")
    if summary_file:
        with open(summary_file, "a") as f:
            f.write(f"### {title}\n\n[View invocation results]({url})\n")


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
    parser.add_argument(
        "extra_flags",
        nargs="*",
        help="Extra flags to pass to bazel test, after --.",
    )
    opts = parser.parse_args()

    if opts.validate_env:
        validate_env()

    package = opts.package

    returncode = run_tests(opts.package, opts.extra_flags)
    if returncode != 0:
        sys.exit(returncode)


if __name__ == "__main__":
    main()
