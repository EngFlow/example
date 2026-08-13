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
# rules_apple passes `${BASHPID:-$$}` for that, at two sites in
# ios_xctestrun_runner.template.sh. At the release call it is a plain top-level
# line and yields the runner. At our call it is wrapped in a command substitution
# -- the runner needs the UDID we print -- and BASHPID is fork-sensitive, so it
# yields the short-lived process that ran us instead. Plain `$$` would have been
# correct at both, since it keeps the starting shell's value across a fork.
# Upstream fix pending; until then we correct it here.
#
# Not merely a mismatched release: the lease names a process that exits the moment
# we do, so the daemon's release-on-exit watcher deletes the device while the test
# is still using it.
#
# Which is also what makes the check below possible. The substitution's body is a
# single command, so bash execs it in place rather than forking again: we *are*
# that subshell, so the pid we are handed is our own and our parent is the runner.
# With an intermediate shell it would be a third pid -- unrecognizable, and PPID
# would name something equally doomed.
if [[ "${XCTESTRUN_RUNNER_PID:-}" == "$$" ]]; then
  readonly lease_pid="$PPID"
else
  readonly lease_pid="${XCTESTRUN_RUNNER_PID:-$$}"
fi

url_encoded_device_type="${SIMULATOR_DEVICE_TYPE// /%20}"

curl \
  --silent \
  --fail-with-body \
  --unix-socket "$socket" \
  --retry 5 \
  --retry-connrefused \
  --request POST \
  "http:/-/simulator/$lease_pid?exclusive=$exclusive&deviceType=$url_encoded_device_type&os=iOS&version=$version"
