# Orphaned simulator fix

Customers reported resource contention caused by `launchd_sim` processes that
had been running for days, tied to CoreSimulator devices the daemon no longer
knew about:

```text
PID  PPID    RSS     ELAPSED  COMMAND
78247     1   9728  05-23:05:41  launchd_sim .../Devices/B9A13CD5-.../data/var/run/launchd_bootstrap.plist
78293     1  11600  05-23:05:40  launchd_sim .../Devices/88362C6D-.../...
78337     1   9968  05-23:05:40  launchd_sim .../Devices/B8CD72C0-.../...
```

This document explains the two root causes and the fix. See
[`LEASE_LIFECYCLE.md`](LEASE_LIFECYCLE.md) for the full lease state machine
this fix adds to (Phase 9).

## Root causes

Every existing cleanup path in `SimulatorManager.swift` is event-driven: an
explicit `DELETE /simulator/<pid>`, a PID-exit watcher, an idle timer, or a
device getting rediscovered by name the next time its config is leased
again. There was no path that checked the manager's bookkeeping against what
CoreSimulator actually had running. Two specific gaps let devices escape all
of those events at once.

### 1. Daemon restarts drop leases without touching their devices

`start.sh` replaces the daemon on every version change. On startup,
`restoreLeases()` (`SimulatorManager.swift:166`) re-adopts a persisted lease
only if its PID is still alive *and* its recorded process start time matches
(to rule out PID reuse). A lease that fails either check is dropped —
intentionally, per the existing code comment: "not released, not cleaned up,
just forgotten." The device itself is never shut down or deleted.

The intended recovery path was that `createBase`/`clone` look up devices by
name, so an orphaned device would get picked up and reference-counted again
the next time something leased that same `SimulatorConfig`. If that exact
config was never requested again, nothing ever looked for the device again —
it, and its `launchd_sim`, ran forever.

### 2. Failed `simctl delete` calls were swallowed silently

In `delete()` (`SimulatorManager.swift:758-792`), the slot was reset to
`.empty` and the reference-count entry removed in a `defer` — regardless of
whether the `simctl delete` call inside it actually succeeded. Both call
sites invoked this as `try? await delete(...)`, discarding any error with no
retry. If `simctl delete` failed for any reason (CoreSimulator daemon busy, a
lingering child process, disk I/O), the manager's bookkeeping said "deleted"
while the real device kept running — and since its slot was now empty, the
manager would never look at that UDID again.

Both gaps produce the same outcome: a real, running simulator with zero
corresponding state in the manager.

## The fix

### Retry `simctl delete` before giving up

`SimulatorControl.swift`, `SimulatorDeleteOrExistenceMutex.unlockedDelete`
now retries the underlying `simctl delete` up to 3 times, 2 seconds apart,
before rethrowing. This doesn't touch `SimulatorManager`'s actor-isolated
slot state machine, so it carries no risk to the "mutate slot before the
first `await`" invariant documented above `getSimulator()`. It simply makes
the existing call sites succeed more often instead of falling straight
through to `try?`.

### Periodic orphan reaper

The real fix: a sweep that reconciles the manager's state against reality,
independent of any lease event, so it catches a device regardless of *how*
it became untracked.

- **`SimulatorControl.listManagedClones()`** (new protocol method) lists
  every simulator whose name starts with `EXAMPLE_BAZEL_CLONE_` — the prefix
  this manager already uses for every clone it creates
  (`SimulatorConfig.cloneDeviceName`), now hoisted into the shared constant
  `managedCloneNamePrefix`. Base simulators (`EXAMPLE_BAZEL_BASE_...`) are
  excluded — they're intentionally long-lived templates and are never
  reference-counted, so they must never be touched by the reaper. Anything
  without this prefix (a developer's own simulator, Xcode's own devices) is
  untouched.
- **`SimulatorManager.reapOrphanedSimulators()`** (new, private) computes
  `known = Set(referenceCount.keys)` and treats any listed clone UDID not in
  that set as an orphan candidate. `referenceCount` is the right thing to
  check: a device gets an entry the instant it's claimed, before any
  `await`, and the entry is removed only in `delete()` — including while the
  device sits in its idle-timer grace period, where the count is `0` but the
  key stays. So "no entry" reliably means "the manager has no idea this
  exists."
- **Two-sweep confirmation.** A clone that's mid-creation exists on disk (via
  `simctl clone`) for a moment before `createCloneTask` resumes and records
  it in `referenceCount`. To avoid mistaking that window for an orphan, a
  device must show up as unknown on two consecutive sweeps
  (`previousOrphanCandidates` intersected with the current sweep's
  candidates) before it's deleted.
- **Deletes bypass `delete()`.** An orphan has no slot pointing at it in
  `simulatorSlots`, so there's nothing for `delete()`'s slot bookkeeping to
  update. The reaper calls `simulatorControl.delete()` directly instead — the
  same lower-level operation `delete()` itself wraps.
- **`SimulatorManager.startReaper(interval:)`** (new, public) runs the sweep
  on a loop and is started from `Main.swift` right after `restoreLeases()`.
  The interval is configurable via the new `--reap-interval-seconds` flag
  (default 300; `0` disables the reaper), and the task is cancelled in
  `deinit` alongside the other background tasks.

## Files changed

| File | Change |
|:-----|:-------|
| `SimulatorControl.swift` | Retry logic in `unlockedDelete`; new `listManagedClones()`; hoisted `managedCloneNamePrefix` constant |
| `SimulatorManager.swift` | New `startReaper(interval:)` and `reapOrphanedSimulators()`; new `reaperTask` and `previousOrphanCandidates` state |
| `Main.swift` | New `--reap-interval-seconds` flag; starts the reaper after `restoreLeases()` |
| `LEASE_LIFECYCLE.md` | Corrected Phase 8's claim that nothing hunts down orphans; added Phase 9 describing the reaper |

## What this does not fix

- The slot state machine itself (`SimulatorSlot` cases, `getSimulator`, the
  "mutate before first `await`" rule) is unchanged. The reaper works
  alongside it by going straight to `simulatorControl`, so the delicate
  actor-isolation invariant didn't need to be touched.
- The Go port at `experiments/yannic/macsimulatormanager/go` was out of
  scope for this fix — the bug report and investigation were both scoped to
  the Swift implementation.

## Verification status

There is no `BUILD` file or `Package.swift` for this target yet, so it isn't
wired into Bazel and can't be built with `swift build` either. This change
has been verified by code review against the existing invariants (see
`LEASE_LIFECYCLE.md`), not by compiling or running it. Before relying on
this in production:

1. Set up a build target (Bazel or an ad hoc `Package.swift`) so this code
   compiles and can be typechecked — it currently depends on `ShellOut`,
   `ArgumentParser`, and SwiftNIO, none of which are vendored here.
2. Manually exercise the restart-orphan path: lease a config, `kill -9` the
   daemon, start a new instance with a short `--reap-interval-seconds`, and
   confirm the orphaned clone disappears from `xcrun simctl list devices`
   within two sweep intervals without touching unrelated simulators.
