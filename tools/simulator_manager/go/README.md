# Mac Simulator Manager (Go)

This is a Go translation of the Swift Mac Simulator Manager located in `../swift/`.

## Architecture

The simulator manager is an HTTP server that manages iOS/macOS simulator instances for testing. It provides lease-based access to simulators with the following features:

- **Lease Management**: PIDs can lease simulators (exclusively or shared)
- **Automatic Cleanup**: Simulators are automatically deleted when idle
- **Persistence**: Leases are persisted to disk so daemon restarts don't lose state
- **Base + Clone Pattern**: Creates base simulators and clones them for efficiency
- **Child Process Management**: Can launch and monitor startup processes

## Key Components

### Main Application (`main.go`)
Entry point that parses command-line arguments and starts the server.

### HTTP Server (`http_server.go`)
Serves requests on a Unix domain socket with endpoints:
- `POST /simulator/<pid>` - Lease a simulator
- `DELETE /simulator/<pid>` - Release a simulator
- `GET /version` - Get manager version
- `GET /leases` - Get count of live leases
- `POST /shutdown` - Shutdown the server

### Simulator Manager (`simulator_manager.go`)
Core orchestration logic:
- Manages simulator slots per configuration
- Handles lease/release operations
- Tracks reference counts
- Implements automatic deletion with LRU eviction

### Simulator Control (`simulator_control.go`)
Low-level interface to `simctl`:
- Creates base simulators
- Clones simulators
- Boots and shuts down simulators
- Deletes simulators

### Lease Store (`lease_store.go`)
Persists leases to disk in JSON format with atomic writes. Includes process start time to detect PID reuse.

### Supporting Components
- `lru_set.go` - LRU cache for tracking recently used configurations
- `pty.go` - PTY creation for child process I/O
- `logger.go` - Structured logging setup

## Translation Notes

### Differences from Swift

These are concrete, verified behavioral or structural differences between the
two implementations -- not just "different language, same thing" restatements.

1. **Concurrency model**:
   - Swift's `SimulatorManager` and `SimulatorControl` are actors, so the
     compiler serializes access and only allows suspension at explicit
     `await` points. Go has no equivalent, so the same invariants are
     enforced by hand with `sync.Mutex`, manually unlocking around any
     blocking call (channel receive, `simctl` invocation) and re-locking
     afterward -- easy to get subtly wrong in a future change, unlike the
     actor version.
   - Coalescing concurrent callers onto one in-flight operation (`getBase`,
     `createBase`, `clone`) uses Swift's `Task<T, Error>`, which is directly
     awaitable and memoizes its result. Go instead uses a buffered channel
     (`chan taskResult`) that every caller receives from.
   - `SimulatorDeleteOrExistenceMutex`, which serializes delete/existence
     checks for a given device name, is a hand-rolled actor with an explicit
     waiter queue in Swift; Go uses a plain `sync.Mutex`.

2. **Leaser-exit detection is slower in Go**:
   - Swift watches for a leaser's exit with `DispatchSource.makeProcessSource`
     (kqueue `EVFILT_PROC`), so `release` runs as soon as the kernel reports
     the exit.
   - Go's `registerReleaseOnExit` instead polls once a second with
     `time.Ticker` + `kill(pid, 0)`, so reclaiming a dead leaser's simulator
     can lag up to ~1s behind Swift. (The separate idle-deletion timer in
     `pendingDeletion` already polls once a second in *both* implementations,
     so that part carried over unchanged.)

3. **`POST /shutdown` is abrupt in Go, graceful in Swift**:
   - Swift's only shutdown path is `POST /shutdown`, which triggers
     SwiftNIO's `ServerQuiescingHelper`: stop accepting connections, let
     in-flight ones finish, then fall through to the cleanup code that
     removes the socket and PID files.
   - Go additionally handles SIGINT/SIGTERM by calling `http.Server.Shutdown`
     (a comparable graceful drain), but its `POST /shutdown` handler just
     calls `os.Exit(0)` from a goroutine after writing the response. That
     skips draining any other in-flight requests and skips the deferred
     socket/PID-file cleanup in `HTTPServer.Run`, which only runs after
     `server.Serve()` returns -- which `os.Exit` prevents. An HTTP-triggered
     shutdown in the Go version can leave stale socket/PID files behind.

4. **Post-boot script failures lose detail in Go**:
   - Swift runs the post-boot script through the same `subprocess`/`shellOut`
     helper used for every `simctl` call, so a failure comes back as a
     `ProcessError` with captured stdout/stderr.
   - Go's `Clone` invokes the post-boot script directly with `exec.Command`
     instead of the shared `subprocess`/`simctl` helper: stdout/stderr are
     discarded rather than captured, and a failure surfaces as a wrapped
     `*exec.ExitError` rather than a `*ProcessError`.

5. **`--post-boot` required vs. optional**:
   - Swift declares `postBoot` as a non-optional `String` with no default, so
     `swift-argument-parser` requires the flag and fails startup without it.
   - Go's flag defaults to `""` and is treated as "skip the post-boot step",
     so it's optional.

6. **Debug logging is unreachable in Go**:
   - Go's `slog` handler is hardcoded to `slog.LevelInfo`, so every
     `Debug`-level call (reference-count changes, existing-simulator lookups)
     is compiled but never emitted, and there's no flag to raise the level.
   - Swift's `os.Logger` calls at `.debug` are still captured live by the
     unified logging system (visible via `log stream`/Console), just not
     persisted long-term.

7. **HTTP framework**:
   - Swift hand-rolls the server on SwiftNIO: a channel pipeline of
     `AccumulatedHTTPHandler` (buffers head/body/end into one in-memory
     request) followed by `SimulatorManagerHTTPHandler` (parses
     method/path/query), with one task per connection.
   - Go uses the standard library's `net/http` + `http.ServeMux`, which
     already delivers a fully parsed, buffered `*http.Request` per call, so
     there's no need for an equivalent two-stage accumulate/parse pipeline.

8. **Child-process output capture**:
   - Swift watches each PTY with `DispatchSource.makeReadSource`
     (event-driven, woken by the runloop on readability).
   - Go uses pipes instead of PTYs (to avoid CGO) and parks a dedicated
     goroutine in a blocking `Read` loop per pipe. This works identically
     for line-buffered output capture but wouldn't preserve interactive
     terminal behavior if child processes expected a real TTY.

9. **JSON serialization**: both use built-in JSON support with struct tags;
   no behavioral difference here.

### Build

```bash
# With Bazel
bazel build //experiments/yannic/macsimulatormanager/go:macsimulatormanager

# With Go
cd experiments/yannic/macsimulatormanager/go
go build -o macsimulatormanager
```

### Usage

```bash
./macsimulatormanager \
  --version="1.0.0" \
  --pid-path="/tmp/simulator-manager.pid" \
  --unix-socket-path="/tmp/simulator-manager.sock" \
  --delete-recently-used-idle-after=300 \
  --delete-idle-after=60 \
  --recently-used-capacity=1 \
  --post-boot="/path/to/post-boot-script.sh" \
  --lease-path="/tmp/leases.json"
```
