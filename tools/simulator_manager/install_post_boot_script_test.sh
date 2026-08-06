#!/bin/bash

# Tests for install_post_boot_script.sh.
#
# The bug these cover: the post-boot script is copied out of runfiles, so the
# copy inherits the runfile's mode. On RBE that mode is read-only, and a second
# copy over it -- which happens on every daemon upgrade -- failed with
#
#   cp: /tmp/simulator_manager.scripts/prepare_simulator.sh: Permission denied
#
# Locally, runfiles are user-writable, so these tests set the read-only mode
# themselves rather than relying on the environment to produce it. That is the
# whole reason the bug reached a customer: it cannot reproduce on a dev machine.

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

readonly install="$(rlocation _main/tools/simulator_manager/install_post_boot_script)"

failures=0

function fail() {
  echo >&2 "❌ ${FUNCNAME[1]}: $1"
  failures=$((failures + 1))
}

# A fresh scratch directory per test, so one test's leftovers cannot mask
# another's behavior.
function new_tmpdir() {
  mktemp -d "${TEST_TMPDIR:-/tmp}/install_test.XXXXXX"
}

# Mimics a runfile: executable, not writable. Named after the body so repeated
# calls in one directory do not collide -- the first file is already unwritable,
# so reusing the name would fail the redirect rather than the assertion.
function new_readonly_src() {
  local -r dir="$1"
  local -r body="$2"
  local -r src="$dir/prepare_simulator.$body"
  printf '#!/bin/bash\necho %s\n' "$body" > "$src"
  chmod 555 "$src"
  echo "$src"
}

# The regression test. Without `cp -f` this is the customer-visible failure.
function test_overwrites_read_only_destination() {
  local -r dir="$(new_tmpdir)"
  local -r src="$(new_readonly_src "$dir" v2)"
  local -r dest="$dir/scripts/prepare_simulator.sh"

  # Stand in for the copy a previous daemon version left behind: same
  # read-only mode the installer itself produces.
  mkdir -p "$(dirname "$dest")"
  printf '#!/bin/bash\necho v1\n' > "$dest"
  chmod 555 "$dest"

  local output
  if ! output="$("$install" "$src" "$dest" 2>&1)"; then
    fail "installing over a read-only destination failed: $output"
    return
  fi

  # The new contents must actually be there; succeeding without replacing the
  # file would leave workers running a stale post-boot script.
  local -r got="$(< "$dest")"
  if [[ "$got" != *v2* ]]; then
    fail "destination still holds the old script: $got"
  fi
}

# The first start on a worker: nothing to overwrite, parent directory absent.
function test_creates_destination_and_parents() {
  local -r dir="$(new_tmpdir)"
  local -r src="$(new_readonly_src "$dir" v1)"
  local -r dest="$dir/nested/scripts/prepare_simulator.sh"

  local output
  if ! output="$("$install" "$src" "$dest" 2>&1)"; then
    fail "installing to a fresh path failed: $output"
    return
  fi

  if [[ ! -f "$dest" ]]; then
    fail "destination was not created"
  fi
}

# The installed copy has to be runnable by the daemon, which executes it
# directly rather than passing it to a shell.
function test_installed_script_is_executable() {
  local -r dir="$(new_tmpdir)"
  local -r src="$(new_readonly_src "$dir" hello)"
  local -r dest="$dir/scripts/prepare_simulator.sh"

  "$install" "$src" "$dest" > /dev/null 2>&1

  if [[ ! -x "$dest" ]]; then
    fail "installed script is not executable: $(ls -l "$dest")"
  fi

  local -r got="$("$dest")"
  if [[ "$got" != hello ]]; then
    fail "installed script did not run as expected: $got"
  fi
}

# `-f` must unlink rather than truncate: a daemon already executing the old copy
# keeps its inode, instead of having the bytes rewritten under it. Verified via
# a hard link, which observes the original inode after the replacement.
function test_replaces_rather_than_truncates() {
  local -r dir="$(new_tmpdir)"
  local -r src="$(new_readonly_src "$dir" v2)"
  local -r dest="$dir/scripts/prepare_simulator.sh"

  mkdir -p "$(dirname "$dest")"
  printf '#!/bin/bash\necho v1\n' > "$dest"
  chmod 555 "$dest"
  local -r witness="$dir/scripts/witness"
  ln "$dest" "$witness"

  "$install" "$src" "$dest" > /dev/null 2>&1

  local -r got="$(< "$witness")"
  if [[ "$got" != *v1* ]]; then
    fail "old inode was modified in place rather than replaced: $got"
  fi
}

# Repeated upgrades must keep working; the mode the installer leaves behind is
# the mode the next upgrade has to cope with.
function test_repeated_installs() {
  local -r dir="$(new_tmpdir)"
  local -r dest="$dir/scripts/prepare_simulator.sh"

  local i
  for i in 1 2 3; do
    local src
    src="$(new_readonly_src "$dir" "v$i")"
    local output
    if ! output="$("$install" "$src" "$dest" 2>&1)"; then
      fail "install #$i failed: $output"
      return
    fi
  done

  local -r got="$(< "$dest")"
  if [[ "$got" != *v3* ]]; then
    fail "final install did not take effect: $got"
  fi
}

function test_rejects_wrong_arg_count() {
  if "$install" only-one-arg > /dev/null 2>&1; then
    fail "expected failure with a single argument"
  fi
}

test_overwrites_read_only_destination
test_creates_destination_and_parents
test_installed_script_is_executable
test_replaces_rather_than_truncates
test_repeated_installs
test_rejects_wrong_arg_count

if ((failures > 0)); then
  echo >&2 "$failures test(s) failed"
  exit 1
fi

echo "✅ all tests passed"
