#!/bin/bash

set -euo pipefail

readonly plist="/tmp/$SIMULATOR_UDID.simulator.defaults.plist"
trap 'rm -f "$plist"' EXIT

function set_or_add_to_simulator_app_defaults() {
  local -r _keypath="$1"
  local -r _type="$2"
  local -r _value="$3"
  IFS=':' read -r -a _parts <<< "$_keypath"

  local -r _last_index=$((${#_parts[@]} - 1))

  # Export the plist to a temporary file
  /usr/bin/defaults export com.apple.iphonesimulator "$plist"

  # Create intermediate dicts
  local _prefix=""
  for ((i = 0; i < ${#_parts[@]} - 1; i++)); do
    _prefix="$_prefix:${_parts[i]}"
    /usr/libexec/PlistBuddy -c "Print $_prefix" "$plist" \
      > /dev/null 2>&1 || /usr/libexec/PlistBuddy -c "Add $_prefix dict" "$plist"
  done

  # Set or add the final key
  local -r _full="$_prefix:${_parts[$_last_index]}"
  if
    ! /usr/libexec/PlistBuddy -c "Set $_full $_type $_value" "$plist" \
      2> /dev/null
  then
    /usr/libexec/PlistBuddy -c "Add $_full $_type $_value" "$plist"
  fi

  # Import the modified plist back to the simulator
  /usr/bin/defaults import com.apple.iphonesimulator "$plist"
}

# Simulator.app keeps every device's preferences in one host domain, and the
# function above rewrites all of it. Run unlocked, this races the same script
# booting another device: each imports a copy without the other's change, and
# the second import drops the first's. flock, rather than a lock directory, is
# released by the kernel if its holder dies, so it can never go stale. perl
# because macOS ships no flock(1), and it waits rather than `exec`ing, which
# would close the lock's descriptor.
readonly defaults_lock="/tmp/simulator_manager.iphonesimulator_defaults.lock"
function with_defaults_lock() {
  perl -MFcntl=:flock -e '
    open(my $lock, ">>", shift) or die "open: $!";
    flock($lock, LOCK_EX) or die "flock: $!";
    system(@ARGV) == 0 or exit(($? >> 8) || 1);
  ' "$defaults_lock" "$@"
}

# Disable hardware keyboard
export plist
export -f set_or_add_to_simulator_app_defaults
with_defaults_lock bash -c \
  'set -euo pipefail; set_or_add_to_simulator_app_defaults "$@"' _ \
  "DevicePreferences:$SIMULATOR_UDID:ConnectHardwareKeyboard" "bool" "false"

# Disable slide typing prompt
/usr/bin/xcrun simctl spawn "$SIMULATOR_UDID" \
  defaults write com.apple.keyboard.preferences \
  DidShowContinuousPathIntroduction 1
