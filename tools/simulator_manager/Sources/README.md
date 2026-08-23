# Mac simulator manager

A long-running daemon that manages the lifecycle of iOS Simulator devices and
hands them out, over HTTP, as leased resources for tests running on a Mac
worker. It exists so that concurrent test runs share a small pool of
simulators instead of each provisioning and tearing down its own, which is
slow and resource-hungry.

The daemon speaks HTTP over a Unix domain socket rather than a TCP port,
since it is only ever talked to by processes on the same machine.

## Building it

```bash
bazel build //experiments/yannic/macsimulatormanager/swift:macsimulatormanager
```

Third-party dependencies (`ShellOut`, `swift-argument-parser`, SwiftNIO) are
resolved via [`rules_swift_package_manager`](https://github.com/cgrindel/rules_swift_package_manager)
from the `Package.swift` / `Package.resolved` pair in this directory, not
hand-vendored. If you change `Package.swift`, regenerate `Package.resolved`
with `swift package resolve` and run `bazel mod tidy` at the repo root to
pick up any new or changed external repos in `MODULE.bazel`.

## Running it

`Main.swift` is a `swift-argument-parser` command; `bazel run` works the same
way, with arguments after `--`. Notable options:

- `--pid-path` / `--unix-socket-path` — where the daemon writes its PID file
  and creates the listening socket.
- `--delete-idle-after` / `--delete-recently-used-idle-after` — how long an
  unleased simulator is kept around before deletion, depending on whether its
  config was recently leased (see [Idle deletion](#idle-deletion)).
- `--recently-used-capacity` — how many distinct simulator configs count as
  "recently used" at once.
- `--startup-process` (repeatable) — extra processes to launch alongside the
  daemon; see [Child processes](#child-processes).
- `--post-boot` — a script run against every freshly booted clone (see
  [`SimulatorControl.swift`](SimulatorControl.swift)).
- `--lease-path` — where leases are mirrored to disk so a replacement daemon
  can adopt them; see [Restarts and lease persistence](#restarts-and-lease-persistence).

The `--version` flag is not read from source; it is passed in externally
(e.g. by a wrapper script) so the manager doesn't need to be recompiled just
to change how it reports its own version.

## HTTP API

Requests are parsed by `SimulatorManagerHTTPHandler.swift` and routed by
`HTTPServer.swift` on the first path component:

| Method | Path                | Query params                              | Description |
|--------|---------------------|--------------------------------------------|--------------|
| `POST`   | `/simulator/<pid>` | `exclusive`, `deviceType`, `os`, `version` | Lease a simulator matching the given config to the process `<pid>`. Returns the simulator's UDID. |
| `DELETE` | `/simulator/<pid>` |                                             | Release the simulator leased to `<pid>`. |
| `GET`    | `/version`         |                                             | The daemon's version string. |
| `GET`    | `/leases`          |                                             | The number of leases whose leasing process is still alive; for diagnostics. |
| `POST`   | `/shutdown`         |                                             | Begin a graceful shutdown. |

`exclusive=1` requests a simulator that no other lease may share; otherwise
the manager may hand out a simulator that is already leased non-exclusively
for the same config. Request parsing and response mapping live in
[`SimulatorRequestHandler.swift`](SimulatorRequestHandler.swift).

## Architecture

```
HTTPServer (SwiftNIO, Unix domain socket)
  └─ AccumulatedHTTPHandler       buffers HTTP head/body/end into one FullHTTPRequest
  └─ SimulatorManagerHTTPHandler  parses method/path/query into a SimulatorManagerRequest
  └─ SimulatorRequestHandler      maps HTTP requests to SimulatorManager calls
       └─ SimulatorManager (actor)   lease/slot/reference-count bookkeeping
            └─ SimulatorControl      wraps `xcrun simctl` (create/clone/boot/delete)
```

### `SimulatorManager`

[`SimulatorManager.swift`](SimulatorManager.swift) is the core state machine,
implemented as an actor so its bookkeeping is safe under concurrent leases.
For each `SimulatorConfig` (device type, OS, version) it keeps an array of
slots, each of which is `empty`, `pendingCreation`, `active`, `pendingDeletion`,
or `deleting`. Leasing a config walks the slots in a fixed preference order
(reuse an active non-exclusive simulator, then a pending deletion, then an
empty slot, then a pending creation) and either reuses what's there or clones
a fresh device from a per-config base simulator (created lazily and cached in
`getBaseSimulatorTasks`).

Every active simulator has a reference count. Leasing increments it; releasing
decrements it, and it is only queued for deletion once it drops to zero, so a
non-exclusive simulator with multiple leasers survives until all of them
release it.

### Idle deletion

Once a simulator's reference count hits zero it isn't deleted immediately —
`pendingDeletion` schedules a delayed delete so a device can be reused by the
next lease for the same config. The wait is either `deleteIdleAfter` or the
longer `deleteRecentlyUsedIdleAfter`, chosen by whether that config appears in
`recentlyLeased`, an `LRUSet` (see [`LRUSet.swift`](LRUSet.swift)) capped at
`recentlyUsedCapacity` distinct configs. This keeps simulators for
in-demand configs around longer while letting one-off configs get cleaned up
quickly.

### Restarts and lease persistence

A new daemon version replaces the running one (the caller kills the old
process and starts the new one), which would otherwise lose track of leases
held by tests that are still running. `LeaseStore.swift` mirrors every lease
change to a JSON file; on startup, `restoreLeases()` reads it back and rebuilds
enough state (the lease, the slot holding the device, the reference count, and
an exit listener) for `release` to work normally. A lease is only adopted if
its leasing process is still running under the *same* start time (`kinfo_proc`
via `processStartTime`, not just the same PID — PIDs get recycled) and doesn't
conflict with another lease already restored; otherwise it's dropped, and its
device is picked up again automatically the next time something leases that
config.

A leaser's exit is also watched for directly, via
`DispatchSource.makeProcessSource`, so a lease is released automatically if
its process dies without calling `DELETE /simulator/<pid>`.

### `SimulatorControl`

[`SimulatorControl.swift`](SimulatorControl.swift) wraps `xcrun simctl` calls
(`create`, `clone`, `bootstatus`, `shutdown`, `delete`, `list devices`) behind
a protocol, so `SimulatorManager` can be tested against a fake. Concurrent
calls for the same base/clone name are coalesced onto a single in-flight
`Task`, and deletion/existence checks for a given name are serialized through
`SimulatorDeleteOrExistenceMutex` so a `clone` can't observe a device that's
mid-deletion.

### Child processes

The daemon can launch extra long-lived processes alongside itself
(`--startup-process`). Each one's stdout/stderr is captured through a
`PTY` (see [`PTY.swift`](PTY.swift), needed because plain pipes make some
tools line-buffer differently) and logged line-by-line via `os.Logger`.
These processes are not restarted if they exit.

## Files

| File | Purpose |
|------|---------|
| `Main.swift` | CLI entry point; wires flags into a `SimulatorManager` and `HTTPServer`. |
| `HTTPServer.swift` | SwiftNIO server bound to a Unix domain socket; top-level request routing. |
| `AccumulatedHTTPHandler.swift` | Buffers streamed HTTP request parts into one in-memory request/response. |
| `SimulatorManagerHTTPHandler.swift` | Parses the HTTP request into method/path/query; serializes responses. |
| `SimulatorRequestHandler.swift` | Translates `/simulator` requests into `SimulatorManager` lease/release calls. |
| `SimulatorManager.swift` | Core actor: slots, reference counts, leases, idle deletion, child processes. |
| `SimulatorControl.swift` | `simctl`-backed implementation of creating, cloning, booting, and deleting simulators. |
| `LeaseStore.swift` | Persists leases to disk so a replacement daemon can adopt them. |
| `LRUSet.swift` | Fixed-capacity, least-recently-used set used to track recently leased configs. |
| `PTY.swift` | Minimal pseudo-terminal wrapper used to capture child process output. |
| `Logger.swift` | Shared `os.Logger` subsystem/category helper. |
