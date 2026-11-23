#!/bin/bash

# Tests for release_simulator.sh, rules_apple's `clean_up_simulator_action`.
#
# Two things are under test: the exit code, and the warning line itself. The
# warning matters because it is the only artifact a failed release leaves in a
# log, so it is what a report of this problem is made of; a stub daemon returning
# the real 404 lets these assemble that line end to end without Xcode.
#
# The runner template (rules_apple 5.4.0) invokes this script at line 796 and
# only afterwards, at line 804, exits with the test's own status:
#
#   SIMULATOR_UDID=... "$clean_up_simulator_action_binary"
#   ...
#   if [[ "$test_exit_code" -ne 0 ]]; then
#     echo "error: tests exited with '$test_exit_code'" >&2
#
# Because the template runs under `set -e`, a nonzero exit here would abort the
# script *before* that line. So the fact that a log shows the release warning
# followed by "tests exited with '65'" is itself proof that this script exited 0
# -- the warning cannot be the cause of the 65. Pinning that keeps a future edit
# from turning a failed release into the test's exit code.

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
# The upstream snippet ends with `set -e`, which is left out on purpose: these
# tests count failures and report them at the end, so a failing command must
# not abort the script part way through.
# --- end runfiles.bash initialization v3 ---

readonly release="$(rlocation _main/tools/simulator_manager/release_simulator)"

failures=0

function fail() {
  echo >&2 "❌ ${FUNCNAME[1]}: $1"
  failures=$((failures + 1))
}

# Points the script at a socket path that nothing is listening on, which is what
# a released-too-late or restarted daemon looks like from curl's side.
function socket_with_no_listener() {
  echo "${TEST_TMPDIR:-/tmp}/absent.sock"
}

# Serves one request on a unix socket and replies with `status` and `body`, then
# exits. Prints the socket path, which is the optional fourth argument or else a
# fresh one.
#
# An unreachable socket is not the reported case: curl then fails with an empty
# body, so the warning ends in a bare colon. Reproducing the reported line needs
# a listener that actually returns the daemon's 404 and its message, which is what
# this provides without needing a real daemon, a real simulator, or Xcode.
#
# Framed to match SimulatorManagerHTTPHandler: the body is the message plus a
# trailing newline, with Content-Length counting it and a text/plain type.
#
# Kept under /tmp rather than TEST_TMPDIR because a unix socket path has a ~104
# byte limit that TEST_TMPDIR can exhaust on its own.
function start_stub_daemon() {
  local -r status="$1"
  local -r reason="$2"
  local -r body="$3"
  local -r path="${4:-$(mktemp -u "/tmp/relstub.XXXXXX")}"

  python3 -c '
import socket, sys

path, status, reason, message = sys.argv[1:5]
body = (message + "\n").encode()
head = (
    "HTTP/1.1 " + status + " " + reason + "\r\n"
    "Content-Length: " + str(len(body)) + "\r\n"
    "Content-Type: text/plain\r\n"
    "\r\n"
).encode()

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(path)
server.listen(1)
# Announced only once listening, so a caller that sees the file cannot connect
# before there is anything to accept it.
open(path + ".ready", "w").close()

connection, _ = server.accept()
connection.recv(65536)
connection.sendall(head + body)
connection.close()
' "$path" "$status" "$reason" "$body" > /dev/null 2>&1 &

  local waited=0
  while [[ ! -e "$path.ready" ]]; do
    if ((waited >= 100)); then
      echo >&2 "stub daemon failed to start listening on $path"
      return 1
    fi
    sleep 0.1
    waited=$((waited + 1))
  done

  echo "$path"
}

function stop_stub_daemon() {
  local -r path="$1"
  rm -f "$path" "$path.ready"
}

# The reproduction. A daemon that has never heard of this lease answers 404 with
# a message naming the pid, and the warning has to carry both halves: its own
# prefix and the daemon's explanation. This is the reported line, assembled end to
# end.
function test_warning_reproduces_the_reported_line() {
  local path
  path="$(start_stub_daemon 404 "Not Found" "PID 4242 doesn't have a simulator leased")" || {
    fail "could not start the stub daemon"
    return
  }

  local output
  local status=0
  output="$(
    SIMULATOR_MANAGER_SOCKET="$path" XCTESTRUN_RUNNER_PID=4242 "$release" 2>&1
  )" || status=$?

  # Still exits 0: an unreleasable lease must not become the test's exit code.
  if ((status != 0)); then
    fail "expected exit 0 on a 404 from the daemon, got $status: $output"
  fi

  local -r expected="warning: failed to release simulator lease for pid 4242: PID 4242 doesn't have a simulator leased"
  if [[ "$output" != *"$expected"* ]]; then
    fail "expected the reported warning line, got: $output"
  fi

  stop_stub_daemon "$path"
}

# The discriminating half: when the daemon knows the lease, the release is silent.
# Without this, a script that warned unconditionally would pass every assertion
# above.
function test_a_successful_release_is_silent() {
  local path
  path="$(start_stub_daemon 200 "OK" "Success")" || {
    fail "could not start the stub daemon"
    return
  }

  local output
  local status=0
  output="$(
    SIMULATOR_MANAGER_SOCKET="$path" XCTESTRUN_RUNNER_PID=4242 "$release" 2>&1
  )" || status=$?

  if ((status != 0)); then
    fail "expected exit 0 on a successful release, got $status: $output"
  fi
  if [[ "$output" == *"warning"* ]]; then
    fail "a successful release must not warn, got: $output"
  fi

  stop_stub_daemon "$path"
}

# start.sh puts the daemon's socket under SIMULATOR_MANAGER_STATE_PREFIX, so a
# release given only the prefix must reach that socket rather than the
# well-known one.
function test_releases_through_the_state_prefix() {
  local -r prefix="$(mktemp -u "/tmp/relstub.XXXXXX")"
  local path
  path="$(start_stub_daemon 200 "OK" "Success" "$prefix.sock")" || {
    fail "could not start the stub daemon"
    return
  }

  local output
  output="$(
    SIMULATOR_MANAGER_STATE_PREFIX="$prefix" XCTESTRUN_RUNNER_PID=4242 \
      "$release" 2>&1
  )" || true

  if [[ -n "$output" ]]; then
    fail "expected a silent release through the prefix's socket, got: $output"
  fi

  stop_stub_daemon "$path"
}

# The load-bearing assertion: a release that cannot reach the daemon still exits
# 0, so the runner template proceeds to report the test's own exit code.
function test_exits_zero_when_daemon_is_unreachable() {
  local output
  local status=0
  output="$(
    SIMULATOR_MANAGER_SOCKET="$(socket_with_no_listener)" \
      XCTESTRUN_RUNNER_PID=4242 \
      "$release" 2>&1
  )" || status=$?

  if ((status != 0)); then
    fail "expected exit 0 on an unreachable daemon, got $status: $output"
  fi
}

# The warning must go to stderr: on stdout it would be captured as part of a
# command substitution's value by any caller that reads this script's output.
function test_warning_goes_to_stderr() {
  local on_stdout
  on_stdout="$(
    SIMULATOR_MANAGER_SOCKET="$(socket_with_no_listener)" \
      XCTESTRUN_RUNNER_PID=4242 \
      "$release" 2> /dev/null
  )" || true

  if [[ -n "$on_stdout" ]]; then
    fail "expected nothing on stdout, got: $on_stdout"
  fi
}

# `XCTESTRUN_RUNNER_PID` is what keys the lease, and the warning has to name it,
# since that is what correlates a release failure with the daemon's own lease
# bookkeeping when debugging from logs alone. The fallback when it is unset is
# `PPID`, which here is this test's own `$$`; if the passed pid stopped being
# honored the release would silently target the wrong process.
function test_uses_the_runner_pid_over_its_own() {
  local output
  output="$(
    SIMULATOR_MANAGER_SOCKET="$(socket_with_no_listener)" \
      XCTESTRUN_RUNNER_PID=31337 \
      "$release" 2>&1
  )" || true

  if [[ "$output" != *"pid 31337"* ]]; then
    fail "did not use XCTESTRUN_RUNNER_PID: $output"
  fi
  if [[ "$output" == *"pid $$"* ]]; then
    fail "used its own pid instead of the runner's: $output"
  fi
}

test_exits_zero_when_daemon_is_unreachable
test_warning_goes_to_stderr
test_uses_the_runner_pid_over_its_own
test_warning_reproduces_the_reported_line
test_a_successful_release_is_silent
test_releases_through_the_state_prefix

if ((failures > 0)); then
  echo >&2 "$failures test(s) failed"
  exit 1
fi

echo "✅ all tests passed"
