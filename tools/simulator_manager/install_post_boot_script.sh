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

# Copied alongside and renamed over the destination, rather than copied onto it.
# The rename replaces the destination's inode, so a daemon still executing the
# old copy keeps intact bytes rather than having them rewritten underneath it,
# and the destination is never seen half-written. `cp -f` only does that when
# it cannot open the destination: it truncates a writable one in place. The
# destination is a copy of a runfile and inherits its mode, which on RBE is
# read-only (r-xr-xr-x) but locally is writable.
readonly tmp="$dest.tmp.$$"
trap 'rm -f "$tmp"' EXIT
rm -f "$tmp"
cp "$src" "$tmp"
mv -f "$tmp" "$dest"
