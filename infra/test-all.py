#!/usr/bin/env python3

import os
import subprocess
import sys

def main():
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
            "--build_tag_filters=-todo-pe1188-remote-incompatible",
            "--test_tag_filters=-todo-pe1188-remote-incompatible",
        ]
    else:
        flags += [
            "--platforms=//platform/" + os_arch,
            "--config=opal_bes",
        ]

    targets = [
        "//cpp/...",
        "//docker/...",
        "//genrules/...",
        "//go/...",
        "//java/...",
        "//kotlin/...",
        "//scala/...",
        "//typescript/...",
        "//csharp/...",
        "//perl/...",
        "//python/...",
        "//swift/...",
    ]
    args = ["bazel", "test"] + flags + ["--"] + targets

    result = subprocess.run(args)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
