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

readonly socket="/tmp/simulator_manager.sock"
readonly lease_pid="${XCTESTRUN_RUNNER_PID:-$$}"

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
