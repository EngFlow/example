#!/bin/bash
# rules_apple `clean_up_simulator_action`: releases the lease taken by
# lease_simulator.sh.
#
# Releasing returns the clone to the daemon's idle pool rather than deleting it,
# so the next test of the same configuration reuses a booted device. The daemon
# deletes clones that stay idle past its threshold.
#
# Runs regardless of test success or failure. A failure to release is not fatal:
# the daemon reclaims leases whose owning process has exited.

set -euo pipefail

# Overridable only so the test can point at its own socket; production callers
# leave it unset and get the well-known path.
readonly socket="${SIMULATOR_MANAGER_SOCKET:-/tmp/simulator_manager.sock}"
# Must resolve to the same pid lease_simulator.sh used, or the release names a
# lease that does not exist. See the comment there for why `$$` is not it: on
# rules_apple 4.5.x, which passes no pid, `$$` is this script's own.
readonly lease_pid="${XCTESTRUN_RUNNER_PID:-$PPID}"

if ! response=$(
  curl \
    --silent \
    --fail-with-body \
    --unix-socket "$socket" \
    --request DELETE \
    "http:/-/simulator/$lease_pid"
); then
  echo >&2 "warning: failed to release simulator lease for pid $lease_pid: $response"
  exit 0
fi
