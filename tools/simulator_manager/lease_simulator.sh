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

# The daemon start.sh runs: like start.sh, under SIMULATOR_MANAGER_STATE_PREFIX if
# that is set, so a test that sets only the prefix leases from its own daemon.
# SIMULATOR_MANAGER_SOCKET sends just this request elsewhere, for a test that
# needs to see it. Production callers set neither.
readonly socket="${SIMULATOR_MANAGER_SOCKET:-${SIMULATOR_MANAGER_STATE_PREFIX:-/tmp/simulator_manager}.sock}"

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3, as in this package's other
# scripts. It is what finds the runfiles library, so it can't itself be shared
# through runfiles.
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2> /dev/null \
  || source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2> /dev/null \
  || source "$0.runfiles/$f" 2> /dev/null \
  || source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2> /dev/null \
  || source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2> /dev/null \
  || {
    echo >&2 "ERROR: cannot find $f"
    exit 1
  }
f=
set -e
# --- end runfiles.bash initialization v3 ---

if [[ -z "${SIMULATOR_DEVICE_TYPE:-}" ]]; then
  echo >&2 "error: SIMULATOR_DEVICE_TYPE must be set; set the device_type on the" \
    "test runner or the ios_simulator_device build setting"
  exit 1
fi

# rules_apple reads this script's stdout as the UDID and nothing else, so the
# daemon bootstrap's progress logging has to go to stderr.
"$(rlocation _main/tools/simulator_manager/start)" >&2

# The runtime's own version (26.4), which is what the daemon needs; see the
# script for why that isn't simply SIMULATOR_OS_VERSION.
version="$(
  xcrun simctl list runtimes -j |
    python3 "$(rlocation _main/tools/simulator_manager/ios_runtime_version.py)" \
      "${SIMULATOR_OS_VERSION:-}"
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
# rules_apple passes that pid, as XCTESTRUN_RUNNER_PID, from 5.0.0-rc2 on, and
# that is what we rely on. The runner names itself, which is better evidence than
# anything we could infer from process topology.
#
# The fallback is for a caller that passes nothing, as rules_apple 4.5.x did, and
# it is best-effort. `$$` would certainly be wrong: it names this script, which
# exits as soon as we have printed the UDID, and the daemon's release-on-exit
# watcher would then reclaim the device while the test is still using it.
# `PPID` is right only when the runner is exactly one level up. Called from
# `unused="$( ... )"` under bash 3.2 -- macOS's /bin/bash, which the runner uses
# -- it is not: that bash forks for the substitution, so `PPID` is the fork,
# which exits with us. start_restart_test.sh covers only the passed-pid case for
# that reason.
readonly lease_pid="${XCTESTRUN_RUNNER_PID:-$PPID}"

# Fully percent-encoded, not just its spaces: a device type containing `&`, `#`
# or `+` would otherwise split or truncate the query. Not curl's
# `--data-urlencode`, which encodes a space as `+`; the daemon's URLComponents
# only decodes `%20`.
url_encoded_device_type="$(
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' \
    "$SIMULATOR_DEVICE_TYPE"
)"

# Only a failure to connect is retried. curl's own `--retry` would also repeat a
# 500, which is the daemon reporting that provisioning failed: repeating it
# provisions up to five more times and almost always fails the same way. A failed
# connection (curl's exit 7) means nothing was sent, so it is safe to repeat. It
# happens when another action's start.sh is replacing the daemon between our own
# start.sh and this request: the socket is briefly missing, which
# `--retry-connrefused` would not retry, or not yet listening. The backoff
# matches what `--retry 5` used.
attempt=0
while true; do
  status=0
  # On failure --fail-with-body still writes the daemon's error message to
  # stdout, which rules_apple would capture as the UDID and never show, so it is
  # moved to stderr below.
  udid="$(
    curl \
      --silent \
      --show-error \
      --fail-with-body \
      --unix-socket "$socket" \
      --request POST \
      "http:/-/simulator/$lease_pid?exclusive=$exclusive&deviceType=$url_encoded_device_type&os=iOS&version=$version"
  )" || status=$?
  if ((status != 7 || attempt >= 5)); then
    break
  fi
  sleep $((2 ** attempt))
  attempt=$((attempt + 1))
done
if ((status != 0)); then
  echo >&2 "error: failed to lease a simulator: $udid"
  exit 1
fi
echo "$udid"
