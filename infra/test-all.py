#!/usr/bin/env python3

import os
import subprocess
import sys

def main():
    # All targets that can run in any environment.
    targets = [
        "//...",
    ]

    for key in ("ARCH", "OPAL_RPC_CREDENTIALS", "OS", "REMOTE_EXECUTION"):
        if not os.getenv(key):
            sys.stderr.write(f"{key} not set\n")
            sys.exit(1)

    os_arch = os.getenv("OS") + "_" + os.getenv("ARCH")
    flags = ["--config=ci"]
    if os.getenv("REMOTE_EXECUTION") == "true":
        flags += [
            "--config=remote_" + os_arch,
            "--config=opal",
        ]
    else:
        flags += [
            "--platforms=//platform/" + os_arch,
            "--config=opal_bes",
            "--config=opal_auth",
        ]
    # The //docker/sysbox/... targets should only run in linux + remote
    if os.getenv("REMOTE_EXECUTION") == "true" and os.getenv("OS") == "linux":
        targets += ["//docker/sysbox/dind_test:check_docker",]
    args = ["bazel", "test"] + flags + ["--"] + targets

    result = subprocess.run(args)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
