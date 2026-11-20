#!/bin/bash
# rules_apple `create_simulator_action`: leases a simulator from the simulator
# manager daemon and prints its UDID.
#
# The daemon hands out leases on clones of a per-configuration base simulator, so
# no two concurrent actions share a device. It also releases a lease
# automatically if the leasing process dies, which is what makes this safe
# against crashed tests.
#
# rules_apple contract: read config from SIMULATOR_* env vars, print only the
# UDID to stdout.

set -euo pipefail

# Overridable only so the test can point at its own socket, matching
# release_simulator.sh; production callers leave it unset and get the well-known
# path.
readonly socket="${SIMULATOR_MANAGER_SOCKET:-/tmp/simulator_manager.sock}"

# --- begin runfiles.bash initialization ---
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null ||
  source "$0.runfiles/$f" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
  { echo >&2 "ERROR: cannot find $f"; exit 1; }
set -e
# --- end runfiles.bash initialization ---

if [[ -z "${SIMULATOR_DEVICE_TYPE:-}" ]]; then
  echo >&2 "error: SIMULATOR_DEVICE_TYPE must be set; set the device_type on the" \
    "test runner or the ios_simulator_device build setting"
  exit 1
fi

# rules_apple reads this script's stdout as the UDID and nothing else, so the
# daemon bootstrap's progress logging has to go to stderr.
"$(rlocation _main/tools/simulator_manager/start)" >&2

# The daemon derives the runtime identifier by substituting dots for dashes, so
# it needs the runtime's own version (26.4), not a patch version (26.4.1) which
# would produce the nonexistent com.apple.CoreSimulator.SimRuntime.iOS-26-4-1.
version="$(
  xcrun simctl list runtimes -j |
    python3 -c '
import json, sys
requested = sys.argv[1]
runtimes = [
    r for r in json.load(sys.stdin)["runtimes"]
    if r["platform"] == "iOS" and r["isAvailable"]
]
if not runtimes:
    sys.exit("no available iOS simulator runtimes")
# An exact or prefix match on the requested version wins; otherwise take the
# newest available runtime, matching rules_apple defaulting to latest.
for r in runtimes:
    if requested and (r["version"] == requested or r["version"].startswith(requested + ".")):
        print(r["identifier"].removeprefix("com.apple.CoreSimulator.SimRuntime.iOS-").replace("-", "."))
        break
else:
    print(runtimes[0]["identifier"].removeprefix("com.apple.CoreSimulator.SimRuntime.iOS-").replace("-", "."))
' "${SIMULATOR_OS_VERSION:-}"
)"

# rules_apple's `reuse_simulator` doubles as the exclusivity toggle: tests that
# opt out of reuse are the ones (UI, app-host) that need sole ownership of the
# device.
if [[ -n "${SIMULATOR_REUSE_SIMULATOR:-}" ]]; then
  exclusive=0
else
  exclusive=1
fi

# Lease is keyed on the test runner's pid so the daemon can reclaim the device if
# this test dies without releasing. So the pid has to name a process that lives
# for the whole test.
#
# rules_apple only passes that pid from 5.0.0-rc2 on; 4.5.x calls us with nothing.
# `$$` is the wrong fallback: it is evaluated here, in our own process, so it names
# this script -- which exits as soon as we have printed the UDID. The daemon's
# release-on-exit watcher then reclaims the device while the test is still using
# it, or hands it to a concurrent test. `PPID` is the runner, which lives for the
# whole test.
#
# Prefer the passed value when we have it: the runner naming itself is better
# evidence than our inferring it from process topology, which assumes the runner
# is exactly one level up. That holds for a direct call from `$( ... )`; a
# launcher that forks rather than `exec`s would break it.
readonly lease_pid="${XCTESTRUN_RUNNER_PID:-$PPID}"

url_encoded_device_type="${SIMULATOR_DEVICE_TYPE// /%20}"

curl \
  --silent \
  --fail-with-body \
  --unix-socket "$socket" \
  --retry 5 \
  --retry-connrefused \
  --request POST \
  "http:/-/simulator/$lease_pid?exclusive=$exclusive&deviceType=$url_encoded_device_type&os=iOS&version=$version"
