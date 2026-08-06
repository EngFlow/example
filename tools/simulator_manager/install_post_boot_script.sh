#!/bin/bash

# Installs the simulator manager's post-boot script at a path that outlives the
# action that started the daemon.
#
# On RBE the action workspace is deleted once the test runner exits, so the
# daemon -- which outlives it -- cannot run the script from runfiles. It gets
# copied to a fixed location instead.
#
# Usage: install_post_boot_script.sh SRC DEST

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo >&2 "usage: ${0##*/} SRC DEST"
  exit 2
fi

readonly src="$1"
readonly dest="$2"

mkdir -p "$(dirname "$dest")"

# `-f` matters: the destination is a copy of a runfile and inherited its mode,
# which on RBE is read-only (r-xr-xr-x). Overwriting it with a plain `cp` fails
# with "Permission denied". `-f` unlinks the destination and creates a new file,
# which also leaves any daemon still executing the old copy holding a valid
# inode rather than having the bytes changed underneath it.
cp -f "$src" "$dest"
