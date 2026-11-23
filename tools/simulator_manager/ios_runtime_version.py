"""Prints the version of the newest available iOS simulator runtime.

Reads `xcrun simctl list runtimes -j` on stdin. With an argument, considers only
runtimes matching that version: exactly, or by prefix in either direction, so 26
finds 26.4 and 26.4.1 finds 26.4.

Prints the version taken from the runtime's identifier, not its `version` field.
The daemon derives the identifier by substituting dashes for dots, so it needs
the runtime's own version (26.4), not a patch version (26.4.1) that would
produce the nonexistent com.apple.CoreSimulator.SimRuntime.iOS-26-4-1.

Shared by lease_simulator.sh and start_restart_test.sh, so the test leases the
runtime a real lease would.
"""

import json
import sys


def main():
    requested = sys.argv[1] if len(sys.argv) > 1 else ""
    runtimes = [
        r
        for r in json.load(sys.stdin)["runtimes"]
        if r["platform"] == "iOS" and r["isAvailable"]
    ]
    if requested:
        runtimes = [
            r
            for r in runtimes
            if r["version"] == requested
            or r["version"].startswith(requested + ".")
            or requested.startswith(r["version"] + ".")
        ]
        if not runtimes:
            sys.exit(f"no available iOS simulator runtime matches version {requested}")
    if not runtimes:
        sys.exit("no available iOS simulator runtimes")
    # Take the newest, matching rules_apple defaulting to latest. simctl lists
    # runtimes oldest first, but sort rather than rely on that.
    newest = max(runtimes, key=lambda r: tuple(int(p) for p in r["version"].split(".")))
    prefix = "com.apple.CoreSimulator.SimRuntime.iOS-"
    print(newest["identifier"].removeprefix(prefix).replace("-", "."))


if __name__ == "__main__":
    main()
