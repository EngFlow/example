# `simulator_manager`

A daemon that hands out "leases" on iOS simulators, so that concurrent test
actions on one machine never share a device.

Tests lease a simulator of a given configuration (device type and OS version) and
release it when done. A lease can be *exclusive*, meaning that test has sole
access to the device — needed for app host and UI tests, which drive the device
through a session that cannot be shared with another test. The daemon releases a
lease automatically if the leasing process exits without releasing, so a crashed
test does not strand a device.

Base simulators are created per configuration; leases are granted on clones of
the base. A clone that stays idle past the daemon's threshold is deleted, which
frees disk and memory on remote executors while still allowing a warm device to
be reused shortly after.

## Why

Without this, `rules_apple` looks up a simulator by name and reuses whatever it
finds. Every concurrent test action on a worker adopts the same device, and they
race over it. The loser fails with:

    TestHost encountered an error (Early unexpected exit, operation never
    finished bootstrapping - no restart will be attempted. (Underlying Error: The
    test runner exited with code 0 before establishing connection.))

## How it is wired up

`rules_apple` is **not** patched or forked. Two hooks plug into extension points
that `ios_xctestrun_runner` already provides:

- `lease_simulator.sh` — the runner's `create_simulator_action`. Starts the daemon
  if needed, leases a device, prints its UDID.
- `release_simulator.sh` — the runner's `clean_up_simulator_action`. Releases the
  lease. Runs whether the test passed or failed.

`//ios:ios_leased_simulator_runner` is an `ios_xctestrun_runner` using both. Note
it sets `reuse_simulator = False`: that attribute doubles as the exclusivity
toggle, since tests opting out of reuse are exactly the ones needing sole
ownership.

## Running tests

The simulator device type must be set, or the lease hook fails fast rather than
booting a device for a test that cannot run. It is deliberately not pinned in
`.bazelrc`, because which device profiles exist depends on the installed Xcode's
iOS runtime. Set it in `.bazelrc.user`:

    build:ios --@rules_apple//apple/build_settings:ios_simulator_device="iPhone 17"

Then:

    bazel test --config=ios //ios:HelloAppUITest

Use `xcrun simctl list devicetypes` and `xcrun simctl list runtimes` to see what
is installed locally. A device type with no profile in the installed runtime
fails with `no matching runtimes found`.

## Concurrency and machine capacity

Use `--runs_per_test` to get several simultaneous leases from one target:

    bazel test --config=ios --runs_per_test=3 //ios:HelloConcurrentTest
    bazel test --config=ios --runs_per_test=3 //ios:HelloAppUITest

Each run's log reports its own `-destination id=`; no two concurrent runs should
match. Concurrency is bounded by host memory, not by the daemon. Measured on a
16 GiB `mac2.metal` remote worker with `//ios:HelloAppUITest`:

| runs | result |
| --- | --- |
| 3 | all passed, 238.5s each, deviation 0.0s |
| 5 | 4 of 5 timed out; passing run took 151s |

In both cases leasing was correct — every run got a distinct device. At 5 the
machine simply runs out of memory. Note simulator memory is invisible to
per-action resource accounting, because those processes are children of
`launchd_sim` rather than of the test action, so a pool can look within budget
while the machine swaps. Size executor counts with that in mind.

## Provenance

Vendored from <https://github.com/bazelbuild/rules_apple/pull/2767>, which is
marked "do not merge" and is not in any `rules_apple` release. Local changes:

- The upstream `BUILD.bazel` builds the daemon with an internal `macos_swift_tool`
  macro; a plain `swift_binary` is equivalent.
- Upstream's `start.sh` resolves paths in the author's own repository, and lists a
  `:start_tunnel` target that the PR does not include. Both adjusted.
- Upstream patches `ios_xctestrun_runner.template.sh` to call the daemon
  directly. That is replaced by the two hook scripts above, which reach the same
  API through unmodified `rules_apple`.

The daemon derives a runtime identifier by substituting dashes for dots in the
version, so it needs a runtime version (`26.4`) rather than a patch version
(`26.4.1`, which yields the nonexistent
`com.apple.CoreSimulator.SimRuntime.iOS-26-4-1`). `lease_simulator.sh` resolves
the real runtime version from `simctl` before leasing.

Since this is vendored rather than depended on, updates must be re-copied by
hand; there is no version to bump.
