#!/bin/bash

# Tests what start.sh does to a daemon that still holds live leases.
#
# start.sh runs on *every* lease, not just at boot: lease_simulator.sh invokes it
# before leasing. When it finds a daemon whose version differs from the one the
# action expects, it shuts that daemon down (`/shutdown`, then `kill -9` after a
# timeout, then `killall simulator_manager`). Leases live only in the daemon's
# memory.
#
# So an action starting a new test could destroy the lease bookkeeping for tests
# already in flight. Their runner scripts keep running and later call
# release_simulator.sh, which reached a *different* daemon that never knew about
# them, and reported
#
#   warning: failed to release simulator lease for pid N: PID N doesn't have a simulator leased
#
# This is the only mechanism found so far that drops a lease while the process
# holding it is still alive, which is what that warning requires -- when the
# runner script dies instead, nobody is left to call release at all.
#
# The daemon now mirrors its leases to `<prefix>.leases` and adopts the still-live
# ones at startup, so a restart hands them over instead of dropping them. These
# tests cover both that the warning is gone and that the handover is what removed
# it, rather than upgrades having quietly stopped happening.
#
# These tests drive the real start.sh and a real daemon over a unix socket. They
# use SIMULATOR_MANAGER_STATE_PREFIX so they never touch the well-known
# /tmp/simulator_manager.* paths a live worker daemon uses.
#
# Leasing is driven directly over the socket with a leaser process this test
# controls, rather than through a real rules_apple test action. That keeps the
# leaser's lifetime under the test's control, which is the crux: the warning only
# appears when the lease disappears while its owner is *still running*.
#
# A lease provisions a real simulator, so these need simctl and an available iOS
# runtime; they skip when there is none.

set -uo pipefail

# --- begin runfiles.bash initialization v3 ---
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

readonly start="$(rlocation _main/tools/simulator_manager/start)"
readonly lease="$(rlocation _main/tools/simulator_manager/lease_simulator)"
readonly release="$(rlocation _main/tools/simulator_manager/release_simulator)"

failures=0

function fail() {
  echo >&2 "❌ ${FUNCNAME[1]}: $1"
  failures=$((failures + 1))
}

# Each test gets its own state prefix, so a leftover daemon from one test cannot
# serve another. Kept short: a unix socket path has a ~104 byte limit, which
# TEST_TMPDIR can exhaust on its own.
function new_prefix() {
  mktemp -u "/tmp/smtest.XXXXXX"
}

# `|| true` because this is called on a prefix that may have no daemon, and a
# failing `cat` inside `$(...)` under `set -e` would take the whole script down
# -- silently, and leaving a daemon behind.
function daemon_pid() {
  cat "$1.pid" 2> /dev/null || true
}

function daemon_version() {
  curl --silent --unix-socket "$1.sock" -XGET 'http:/-/version'
}

# The newest available iOS runtime, in the dotted form the daemon turns back into
# a runtime identifier. A lease really does provision a device, so a made-up
# version fails with "Invalid runtime" rather than producing a lease.
#
# Derived from the runtime's identifier, not its `version` field: the daemon
# builds the identifier by substituting dots for dashes, so a patch version like
# 26.4.1 would yield the nonexistent iOS-26-4-1. lease_simulator.sh takes the
# same care for the same reason.
function available_ios_version() {
  xcrun simctl list runtimes -j 2> /dev/null | python3 -c '
import json, sys
runtimes = [
    r for r in json.load(sys.stdin)["runtimes"]
    if r["platform"] == "iOS" and r["isAvailable"]
]
if not runtimes:
    sys.exit(1)
prefix = "com.apple.CoreSimulator.SimRuntime.iOS-"
print(runtimes[-1]["identifier"].removeprefix(prefix).replace("-", "."))
'
}

# Leases with an explicit pid, bypassing lease_simulator.sh so the leaser can be
# a process this test controls rather than a real rules_apple runner script.
function lease_as() {
  local -r prefix="$1"
  local -r pid="$2"
  curl --silent --unix-socket "$prefix.sock" --request POST \
    "http:/-/simulator/$pid?exclusive=1&deviceType=$device_type&os=iOS&version=$ios_version"
}

function release_as() {
  local -r prefix="$1"
  local -r pid="$2"
  SIMULATOR_MANAGER_SOCKET="$prefix.sock" XCTESTRUN_RUNNER_PID="$pid" "$release" 2>&1
}

# A process that outlives the test, standing in for a runner script still running
# while its lease is destroyed underneath it.
#
# The sleep has to comfortably exceed one test's runtime, which is dominated by
# provisioning: creating and booting a base simulator takes minutes on a cold
# machine. A leaser that exits first fails the test for the wrong reason -- the
# daemon reports "exited before its simulator was provisioned" -- so this is set
# far longer than needed rather than tuned close.
#
# Redirects the child's stdout so it does not hold this function's command
# substitution open: `$(...)` reads until EOF on the pipe, and a background
# `sleep` inheriting it would block the caller for the sleep's full duration.
function spawn_leaser() {
  sleep 3600 > /dev/null 2>&1 &
  echo $!
}

# Blocks until `pid` is gone. `wait` is not usable here: the leaser is spawned
# inside a command substitution, so it is not this shell's child and `wait` fails
# with 127 rather than waiting.
# The UDIDs of every device these tests may have created, by name prefix.
function list_test_simulators() {
  xcrun simctl list devices -j 2> /dev/null | python3 -c '
import json, sys
for devices in json.load(sys.stdin)["devices"].values():
    for device in devices:
        if device["name"].startswith("EXAMPLE_BAZEL_"):
            print(device["udid"])
' 2> /dev/null
}

function await_exit() {
  local -r pid="$1"
  local -r timeout="${2:-10}"
  local waited=0
  while kill -0 "$pid" 2> /dev/null; do
    if ((waited >= timeout)); then
      return 1
    fi
    sleep 1
    waited=$((waited + 1))
  done
}

function stop_daemon() {
  local -r prefix="$1"
  local pid
  pid="$(daemon_pid "$prefix")"

  # Devices are named after their configuration, not the state prefix, so all the
  # tests in this file share one device namespace. Ask the daemon to shut down
  # rather than killing it, so any delete it has in flight finishes: a device
  # interrupted mid-delete is still listed under its name but rejected by every
  # operation, and the next test's `getExisting` then adopts it and fails
  # "postBoot failed (isExisting: true) ... Invalid device".
  if [[ -n "$pid" ]]; then
    curl --silent --max-time 10 --unix-socket "$prefix.sock" \
      -XPOST 'http:/-/shutdown' > /dev/null 2>&1
    # Generous, because a shutdown that deletes a device waits on simctl.
    await_exit "$pid" 60 || kill -9 "$pid" 2> /dev/null
  fi

  rm -rf "$prefix.sock" "$prefix.pid" "$prefix.scripts" "${prefix}_start.lock" \
    "$prefix.leases"

  # Belt and braces: a graceful shutdown is not guaranteed to have deleted
  # everything (a lease held by a live process is deliberately left alone), and
  # anything left behind is a device the next test would adopt by name. Each test
  # pays a base-simulator rebuild for this, which is the price of not having tests
  # fail depending on what ran before them.
  delete_test_simulators
}

# The devices these tests provision outlive the daemons that made them, either
# because a daemon was killed or because its lease was still held. Deleting by name
# prefix keeps repeated runs from accumulating simulators, each of which costs
# several GB, and keeps one test's devices from being adopted by the next.
#
# Registered as an EXIT trap so it also runs when a test returns early.
function delete_test_simulators() {
  local udid
  for udid in $(list_test_simulators); do
    # Shut down first: simctl refuses to delete a booted device, and a device left
    # behind is one the next test adopts by name.
    xcrun simctl shutdown "$udid" > /dev/null 2>&1 || true
    xcrun simctl delete "$udid" > /dev/null 2>&1 || true
  done

  # `simctl delete` has returned before the device is gone from the list; the next
  # test would then find it by name and fail on it. Wait for the namespace to be
  # actually clear.
  local waited=0
  while [[ -n "$(list_test_simulators)" ]]; do
    if ((waited >= 30)); then
      echo >&2 "⚠️ test simulators still present after ${waited}s: $(list_test_simulators)"
      return
    fi
    sleep 1
    waited=$((waited + 1))
  done
}

trap delete_test_simulators EXIT

# start.sh only starts a daemon; nothing in the repo asserts that the state
# prefix override actually takes effect, and every test below depends on it.
function test_state_prefix_override_is_honored() {
  local -r prefix="$(new_prefix)"

  if ! output="$(SIMULATOR_MANAGER_STATE_PREFIX="$prefix" "$start" 2>&1)"; then
    fail "start.sh failed: $output"
    return
  fi

  if [[ ! -S "$prefix.sock" ]]; then
    fail "no socket at the overridden prefix: $output"
  fi
  if [[ -e /tmp/simulator_manager.sock && ! -S /tmp/simulator_manager.sock ]]; then
    fail "start.sh touched the well-known path"
  fi

  stop_daemon "$prefix"
}

# The regression test. A version change must not cost an in-flight test its
# lease: start.sh runs on every lease, so an action starting a new test can
# otherwise destroy the bookkeeping for tests already running, and their release
# calls then report a lease the daemon has never heard of.
#
# EXAMPLE_CI_STAGING_VERSION makes the expected version differ from the running
# one without editing start.sh's hardcoded number, which is exactly the
# staging/non-staging mix that can land on one worker.
#
# Asserts the outcome -- the live leaser can still release -- rather than how the
# daemon avoids it. Handing the lease to the replacement and declining to upgrade
# at all are both acceptable; losing the lease is not.
function test_version_change_preserves_a_live_lease() {
  local -r prefix="$(new_prefix)"

  local output
  if ! output="$(SIMULATOR_MANAGER_STATE_PREFIX="$prefix" "$start" 2>&1)"; then
    fail "first start failed: $output"
    return
  fi
  local -r first_pid="$(daemon_pid "$prefix")"

  local -r leaser="$(spawn_leaser)"

  # A successful lease returns a UDID. Checking the response beats releasing and
  # re-leasing to prove it worked: each lease provisions a real device, so a
  # round trip would double an already slow test.
  local -r lease_response="$(lease_as "$prefix" "$leaser")"
  if ! [[ "$lease_response" =~ ^[0-9A-F-]{36}$ ]]; then
    fail "precondition: lease did not return a UDID: $lease_response"
    kill "$leaser" 2> /dev/null
    stop_daemon "$prefix"
    return
  fi

  # A concurrent action wants a different version, so start.sh replaces the
  # daemon holding the lease above.
  if ! output="$(
    SIMULATOR_MANAGER_STATE_PREFIX="$prefix" \
      EXAMPLE_CI_STAGING_VERSION=99999 \
      "$start" 2>&1
  )"; then
    fail "second start failed: $output"
    kill "$leaser" 2> /dev/null
    stop_daemon "$prefix"
    return
  fi

  # Deliberately not asserting whether the daemon was replaced; that is the next
  # test's job. Either the lease was handed over or the upgrade was declined, and
  # both keep the leaser whole. The pid is reported on failure only, as a hint
  # about which path was taken.
  local -r second_pid="$(daemon_pid "$prefix")"

  # The leaser is still alive -- this is the whole point. A dead leaser would make
  # a lost lease correct behavior rather than a bug.
  if ! kill -0 "$leaser" 2> /dev/null; then
    fail "precondition: the leaser died, so this proves nothing about live leases"
    stop_daemon "$prefix"
    return
  fi

  local -r after="$(release_as "$prefix" "$leaser")"
  if [[ "$after" == *"doesn't have a simulator leased"* ]]; then
    fail \
      "a live leaser lost its lease across a version change (daemon $first_pid -> $second_pid): $after"
  fi

  kill "$leaser" 2> /dev/null
  stop_daemon "$prefix"
}

# The mechanism behind the test above, asserted directly: the replacement daemon
# adopts the lease rather than merely leaving the old one alive. Without this, the
# regression test would also pass if start.sh simply stopped upgrading, which
# would fix the warning by abandoning upgrades altogether.
function test_a_new_daemon_adopts_a_live_lease() {
  local -r prefix="$(new_prefix)"

  local output
  if ! output="$(SIMULATOR_MANAGER_STATE_PREFIX="$prefix" "$start" 2>&1)"; then
    fail "first start failed: $output"
    return
  fi
  local -r first_pid="$(daemon_pid "$prefix")"

  local -r leaser="$(spawn_leaser)"
  local -r lease_response="$(lease_as "$prefix" "$leaser")"
  if ! [[ "$lease_response" =~ ^[0-9A-F-]{36}$ ]]; then
    fail "precondition: lease did not return a UDID: $lease_response"
    kill "$leaser" 2> /dev/null
    stop_daemon "$prefix"
    return
  fi

  if ! output="$(
    SIMULATOR_MANAGER_STATE_PREFIX="$prefix" \
      EXAMPLE_CI_STAGING_VERSION=99999 \
      "$start" 2>&1
  )"; then
    fail "second start failed: $output"
    kill "$leaser" 2> /dev/null
    stop_daemon "$prefix"
    return
  fi

  local -r second_pid="$(daemon_pid "$prefix")"
  if [[ "$first_pid" == "$second_pid" ]]; then
    fail "expected the upgrade to replace the daemon, but pid $first_pid remains"
    kill "$leaser" 2> /dev/null
    stop_daemon "$prefix"
    return
  fi

  # The successor is the one holding the lease now, so it must report it as live.
  local -r live="$(curl --silent --unix-socket "$prefix.sock" -XGET 'http:/-/leases')"
  if [[ "$live" != "1" ]]; then
    fail "new daemon $second_pid reports $live live lease(s), expected 1"
  fi

  # And the lease it adopted must be the same device, not a fresh one: adopting
  # the wrong UDID would leave the test's simulator unreferenced and deletable.
  if [[ ! -f "$prefix.leases" ]]; then
    fail "no lease file at $prefix.leases"
  elif ! grep -q "$lease_response" "$prefix.leases"; then
    fail "lease file does not name the leased device $lease_response"
  fi

  kill "$leaser" 2> /dev/null
  stop_daemon "$prefix"
}

# A lease whose process died before the handover must not be adopted: doing so
# would tie up a device with no one left to release it, until the daemon happened
# to be restarted again.
function test_a_new_daemon_drops_a_dead_leasers_lease() {
  local -r prefix="$(new_prefix)"

  local output
  if ! output="$(SIMULATOR_MANAGER_STATE_PREFIX="$prefix" "$start" 2>&1)"; then
    fail "first start failed: $output"
    return
  fi

  local -r leaser="$(spawn_leaser)"
  local -r lease_response="$(lease_as "$prefix" "$leaser")"
  if ! [[ "$lease_response" =~ ^[0-9A-F-]{36}$ ]]; then
    fail "precondition: lease did not return a UDID: $lease_response"
    kill "$leaser" 2> /dev/null
    stop_daemon "$prefix"
    return
  fi

  # Kill the daemon before the leaser, so the exit listener never fires and the
  # lease survives on disk with a pid that is already gone. That is exactly the
  # state a `kill -9` upgrade leaves behind.
  local -r first_pid="$(daemon_pid "$prefix")"
  kill -9 "$first_pid" 2> /dev/null
  kill -9 "$leaser" 2> /dev/null
  await_exit "$leaser"

  if ! output="$(SIMULATOR_MANAGER_STATE_PREFIX="$prefix" "$start" 2>&1)"; then
    fail "second start failed: $output"
    stop_daemon "$prefix"
    return
  fi

  local -r live="$(curl --silent --unix-socket "$prefix.sock" -XGET 'http:/-/leases')"
  if [[ "$live" != "0" ]]; then
    fail "new daemon adopted a dead leaser's lease: $live live lease(s), expected 0"
  fi

  stop_daemon "$prefix"
}

# The other half of the signature: when the version matches, start.sh leaves the
# daemon alone and a live lease survives. Without this, the test above could pass
# because start.sh restarts unconditionally.
function test_same_version_preserves_a_live_lease() {
  local -r prefix="$(new_prefix)"

  local output
  if ! output="$(SIMULATOR_MANAGER_STATE_PREFIX="$prefix" "$start" 2>&1)"; then
    fail "first start failed: $output"
    return
  fi
  local -r first_pid="$(daemon_pid "$prefix")"

  local -r leaser="$(spawn_leaser)"
  local -r lease_response="$(lease_as "$prefix" "$leaser")"
  if ! [[ "$lease_response" =~ ^[0-9A-F-]{36}$ ]]; then
    fail "precondition: lease did not return a UDID: $lease_response"
    kill "$leaser" 2> /dev/null
    stop_daemon "$prefix"
    return
  fi

  # Same version: this is the common case, an action leasing while other tests
  # are already running.
  if ! output="$(SIMULATOR_MANAGER_STATE_PREFIX="$prefix" "$start" 2>&1)"; then
    fail "second start failed: $output"
    kill "$leaser" 2> /dev/null
    stop_daemon "$prefix"
    return
  fi

  local -r second_pid="$(daemon_pid "$prefix")"
  if [[ "$first_pid" != "$second_pid" ]]; then
    fail "daemon was replaced despite an unchanged version: $first_pid -> $second_pid"
  fi

  local -r after="$(release_as "$prefix" "$leaser")"
  if [[ "$after" == *"doesn't have a simulator leased"* ]]; then
    fail "a live lease was lost without a version change: $after"
  fi

  kill "$leaser" 2> /dev/null
  stop_daemon "$prefix"
}

# The lease and the release have to name the same process, and that process has to
# outlive the test. whatever pid reaches the socket must be the one the runner would later release.
#
# $1 is the assignment rules_apple prefixes to the call. rules_apple 5.0.0-rc2 passes
# the runner pid; 4.5.x passes nothing, and then our own `$$` is the trap -- it names
# this script, which exits the moment it has leased. Both shapes have to work.
function test_lease_pid_survives_a_command_substitution() {
  local -r runner_pid_assignment="$1"
  local -r prefix="$(new_prefix)"

  SIMULATOR_MANAGER_STATE_PREFIX="$prefix" "$start" > /dev/null 2>&1
  if [[ -z "$(daemon_pid "$prefix")" ]]; then
    fail "daemon did not start"
    return
  fi

  # Records the request line and never answers, so the lease script blocks on the
  # reply instead of racing us -- the request is already captured by then.
  local -r stub="$prefix.stub.sock"
  local -r captured="$prefix.request"
  nc -lU "$stub" > "$captured" 2>/dev/null &
  local -r stub_pid="$!"

  local waited=0
  while [[ ! -S "$stub" ]]; do
    if ((waited >= 10)); then
      kill "$stub_pid" 2> /dev/null || true
      fail "stub socket never appeared"
      stop_daemon "$prefix"
      return
    fi
    sleep 1
    waited=$((waited + 1))
  done

  # A separate bash stands in for the rules_apple runner script, and records its own pid: that
  # is the pid it should release under, and the one the lease has to match.
  #
  # The command substitution is the whole point --
  # `unused="$(...)"` -- because that is what the testrunner currently does.
  local -r runner_pid_file="$prefix.runner_pid"
  bash -c '
    echo $$ > "$4"
    unused="$(SIMULATOR_MANAGER_SOCKET="$1" SIMULATOR_MANAGER_STATE_PREFIX="$2" \
      SIMULATOR_DEVICE_TYPE="iPhone 16" SIMULATOR_REUSE_SIMULATOR="1" \
      '"$runner_pid_assignment"' "$3")"
  ' _ "$stub" "$prefix" "$lease" "$runner_pid_file" > /dev/null 2>&1 &
  local -r lease_pid="$!"

  # The request arrives well before any reply would; this only waits for it to be
  # written, not for the lease to complete.
  waited=0
  while ! grep -q 'POST /simulator/' "$captured" 2> /dev/null; do
    if ((waited >= 60)); then
      break
    fi
    sleep 1
    waited=$((waited + 1))
  done

  kill "$lease_pid" 2> /dev/null || true
  kill "$stub_pid" 2> /dev/null || true

  # Just the pid from `POST /simulator/<pid>?...`.
  local -r leased_pid="$(
    grep -o 'POST /simulator/[0-9]*' "$captured" 2> /dev/null | head -1 |
      grep -o '[0-9]*$'
  )"

  local -r requester="$(cat "$runner_pid_file" 2> /dev/null || true)"

  if [[ -z "$leased_pid" ]]; then
    fail "no lease request reached the socket"
  elif [[ -z "$requester" ]]; then
    fail "the stand-in runner never recorded its pid"
  elif [[ "$leased_pid" != "$requester" ]]; then
    fail "leased under pid $leased_pid, but the runner would release pid $requester; the lease is keyed on a process that exits as soon as it has leased, so the daemon tears the device down under the test"
  fi

  rm -f "$captured" "$stub" "$runner_pid_file"
  stop_daemon "$prefix"
}

readonly device_type="iPhone%2016"

# Needs no simulator, so these run before the runtime check that can skip the rest.
# rules_apple 5.0.0-rc2's shape, then 4.5.x's -- no assignment at all.
test_lease_pid_survives_a_command_substitution 'XCTESTRUN_RUNNER_PID="${BASHPID:-$$}"'
test_lease_pid_survives_a_command_substitution ''

# Leasing provisions a real device, so without a runtime there is nothing to
# test. Skipping beats failing: the interesting assertions are about start.sh,
# not about what Xcode this machine happens to have.
ios_version="$(available_ios_version)"
readonly ios_version
if [[ -z "$ios_version" ]]; then
  echo "no available iOS simulator runtime; skipping"
  exit 0
fi

echo "using iOS $ios_version on $device_type"

test_state_prefix_override_is_honored
test_version_change_preserves_a_live_lease
test_a_new_daemon_adopts_a_live_lease
test_a_new_daemon_drops_a_dead_leasers_lease
test_same_version_preserves_a_live_lease

if ((failures > 0)); then
  echo >&2 "$failures test(s) failed"
  exit 1
fi

echo "✅ all tests passed"
