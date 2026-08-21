import Foundation
import XCTest

final class SimulatorManagerTests: XCTestCase {
  func test_lease_release_lease() async throws {
    let mockSimulatorControl = MockSimulatorControl()
    let simulatorManager = SimulatorManager(
      simulatorControl: mockSimulatorControl,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
    let leaser: PID = 1234
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let simulator1 =
      try await simulatorManager
        .lease(to: leaser, exclusive: false, config: config)
    let maybeBaseSimulators1 = await mockSimulatorControl.baseSimulators[config]
    let baseSimulators1 = try XCTUnwrap(maybeBaseSimulators1)
    XCTAssert(baseSimulators1.count == 1)
    let baseSimulator1 = baseSimulators1[0]
    let maybeBaseForClone = await mockSimulatorControl.baseForClones[simulator1]
    let baseForClone = try XCTUnwrap(maybeBaseForClone)

    try await simulatorManager.release(for: leaser)
    let maybeBaseSimulators2 = await mockSimulatorControl.baseSimulators[config]
    let baseSimulators2 = try XCTUnwrap(maybeBaseSimulators2)
    XCTAssert(baseSimulators2.count == 1)
    let baseSimulator2 = baseSimulators2[0]

    let simulator2 =
      try await simulatorManager
        .lease(to: leaser, exclusive: false, config: config)
    let maybeBaseSimulators3 = await mockSimulatorControl.baseSimulators[config]
    let baseSimulators3 = try XCTUnwrap(maybeBaseSimulators3)
    XCTAssert(baseSimulators3.count == 2)
    let baseSimulator3 = baseSimulators3[1]

    // Simulator is a clone (not the same as base)
    XCTAssertNotEqual(simulator1, baseSimulator1)
    XCTAssertEqual(baseForClone, baseSimulator1)

    // Even with reuse, after last use of a simulator it's deleted
    XCTAssertNotEqual(simulator1, simulator2)

    XCTAssertEqual(baseSimulator1, baseSimulator2)

    // We don't cache our clones
    XCTAssertNotEqual(baseSimulator2, baseSimulator3)
  }

  func test_lease_reuse() async throws {
    let mockSimulatorControl = MockSimulatorControl()
    let simulatorManager = SimulatorManager(
      simulatorControl: mockSimulatorControl,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
    let leaser1: PID = 1234
    let leaser2: PID = 1235
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let simulator1 =
      try await simulatorManager
        .lease(to: leaser1, exclusive: false, config: config)
    let simulator2 =
      try await simulatorManager
        .lease(to: leaser2, exclusive: false, config: config)

    XCTAssertEqual(simulator1, simulator2)
  }

  func test_lease_exclusive() async throws {
    let mockSimulatorControl = MockSimulatorControl()
    let simulatorManager = SimulatorManager(
      simulatorControl: mockSimulatorControl,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
    let leaser1: PID = 1234
    let leaser2: PID = 1235
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let simulator1 =
      try await simulatorManager
        .lease(to: leaser1, exclusive: true, config: config)
    let simulator2 =
      try await simulatorManager
        .lease(to: leaser2, exclusive: true, config: config)

    XCTAssertNotEqual(simulator1, simulator2)
  }

  func test_lease_twice() async throws {
    let mockSimulatorControl = MockSimulatorControl()
    let simulatorManager = SimulatorManager(
      simulatorControl: mockSimulatorControl,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
    let leaser: PID = 1234
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    _ =
      try await simulatorManager
        .lease(to: leaser, exclusive: true, config: config)

    // swiftformat:disable:next hoistAwait
    try await assertThrowsAsyncError(
      await simulatorManager
        .lease(to: leaser, exclusive: true, config: config)
    )
  }

  func test_release_alone() async throws {
    let mockSimulatorControl = MockSimulatorControl()
    let simulatorManager = SimulatorManager(
      simulatorControl: mockSimulatorControl,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
    let leaser: PID = 1234

    // swiftformat:disable:next hoistAwait
    try await assertThrowsAsyncError(await simulatorManager.release(for: leaser))
  }

  /// A leaser that exits while its simulator is still being provisioned must not
  /// be handed a device.
  ///
  /// `getSimulator()` can await for minutes while it clones, boots and runs the
  /// post-boot script. A leaser killed during that window (e.g. by its build
  /// tool's test timeout while queued for a simulator) used to be noticed only
  /// afterwards, so the lease was released a millisecond after being granted and
  /// the device deleted out from under a test that had already been given the
  /// UDID -- surfacing as "No matching device ... in set".
  func test_lease_leaser_exits_during_provisioning() async throws {
    let mockSimulatorControl = MockSimulatorControl()
    let simulatorManager = SimulatorManager(
      simulatorControl: mockSimulatorControl,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: true
    )
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    // PID 1 is `launchd`, which is alive but not ours; use a PID that cannot be
    // running so `kill(pid, 0)` fails. PID 0 is rejected, and very high PIDs are
    // not portable, so reserve one by spawning a process and reaping it.
    let deadLeaser = try spawnAndReapProcess()

    // swiftformat:disable:next hoistAwait
    await assertThrowsAsyncError(
      try await simulatorManager.lease(to: deadLeaser, exclusive: true, config: config)
    ) { error in
      XCTAssertTrue(
        error is SimulatorManagerError,
        "expected SimulatorManagerError, got \(error)"
      )
    }

    // No lease may be left behind for a leaser that never got a device.
    // swiftformat:disable:next hoistAwait
    try await assertThrowsAsyncError(await simulatorManager.release(for: deadLeaser))
  }
}

/// Liveness of a leaser decides whether its device is reclaimed, so misjudging it
/// either strands devices or pulls one out from under a running test.
final class ProcessIsRunningTests: XCTestCase {
  func test_live_process_is_running() {
    XCTAssertTrue(processIsRunning(PID(getpid())))
  }

  func test_reaped_process_is_not_running() throws {
    XCTAssertFalse(processIsRunning(try spawnAndReapProcess()))
  }

  /// PID 1 (`launchd`) is alive but unsignalable by a non-root user, so
  /// `kill(1, 0)` fails with `EPERM` rather than succeeding. A liveness check that
  /// only tests `kill(...) != 0` reads that as "exited" and releases the lease of
  /// a process that is still running -- which is exactly the
  /// "PID N doesn't have a simulator leased" warning, reported against a live
  /// leaser.
  ///
  /// The daemon runs as `engflow` on workers, not root, so this is reachable
  /// there; when the tests happen to run as root `kill` succeeds outright and the
  /// distinction is moot, hence the guard.
  func test_unsignalable_but_live_process_is_running() throws {
    try XCTSkipIf(getuid() == 0, "as root, kill(1, 0) succeeds and EPERM never arises")

    errno = 0
    XCTAssertNotEqual(kill(1, 0), 0, "precondition: kill(1, 0) should fail for non-root")
    XCTAssertEqual(errno, EPERM, "precondition: the failure should be EPERM, not ESRCH")

    XCTAssertTrue(
      processIsRunning(1),
      "an EPERM from kill() means alive-but-unsignalable, not exited"
    )
  }
}

/// The release path as the test runner actually drives it.
final class SimulatorManagerReleaseTests: XCTestCase {
  private func makeManager(_ control: MockSimulatorControl) -> SimulatorManager {
    SimulatorManager(
      simulatorControl: control,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
  }

  /// The healthy case: a leaser that is still alive releases its own lease and
  /// gets no warning. Verified by hand against a live daemon, so it is pinned
  /// here to stay that way.
  func test_live_leaser_releases_successfully() async throws {
    let control = MockSimulatorControl()
    let manager = makeManager(control)
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    _ = try await manager.lease(to: 1234, exclusive: true, config: config)
    try await manager.release(for: 1234)
  }

  /// Releasing twice must report no-lease the second time rather than
  /// double-decrementing the reference count and deleting a device that a
  /// subsequent lease of the same slot is using.
  func test_double_release_reports_no_lease() async throws {
    let control = MockSimulatorControl()
    let manager = makeManager(control)
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    _ = try await manager.lease(to: 1234, exclusive: true, config: config)
    try await manager.release(for: 1234)

    // swiftformat:disable:next hoistAwait
    try await assertThrowsAsyncError(await manager.release(for: 1234))
  }

  /// One leaser's release must not disturb another's device. Guards the
  /// reference-counting when several tests share a worker.
  func test_release_does_not_affect_other_leases() async throws {
    let control = MockSimulatorControl()
    let manager = makeManager(control)
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let first = try await manager.lease(to: 1234, exclusive: true, config: config)
    let second = try await manager.lease(to: 5678, exclusive: true, config: config)
    XCTAssertNotEqual(first, second)

    try await manager.release(for: 1234)

    let deleted = await control.deletedSimulators
    XCTAssertFalse(
      deleted.contains(second),
      "releasing one lease must not delete another leaser's device"
    )
  }

  /// A non-exclusive device shared by two leasers survives the first release: the
  /// second holder is still using it. Deleting on the first release is what would
  /// produce "No matching device" for the test still running.
  func test_shared_device_survives_first_release() async throws {
    let control = MockSimulatorControl()
    let manager = makeManager(control)
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let first = try await manager.lease(to: 1234, exclusive: false, config: config)
    let second = try await manager.lease(to: 5678, exclusive: false, config: config)
    XCTAssertEqual(first, second, "precondition: non-exclusive leases share a device")

    try await manager.release(for: 1234)

    let deletedAfterFirst = await control.deletedSimulators
    XCTAssertFalse(
      deletedAfterFirst.contains(first),
      "a device still leased by another PID must not be deleted"
    )

    // Once the last holder releases, the device may go.
    try await manager.release(for: 5678)
    let deletedAfterSecond = await control.deletedSimulators
    XCTAssertTrue(
      deletedAfterSecond.contains(first),
      "the last release should retire the device"
    )
  }
}

/// The invariant a user actually feels: two exclusive leases must never name
/// the same device at the same time, and a device must never be deleted while a
/// lease still references it.
final class SimulatorManagerExclusivityTests: XCTestCase {
  /// Records overlaps as they happen rather than inferring them afterwards, so a
  /// failure names the device that was double-leased.
  private actor HeldDevices {
    private var held: Set<SimulatorUDID> = []
    private(set) var overlaps: [SimulatorUDID] = []

    func acquire(_ udid: SimulatorUDID) {
      if held.contains(udid) {
        overlaps.append(udid)
      }
      held.insert(udid)
    }

    func relinquish(_ udid: SimulatorUDID) {
      held.remove(udid)
    }
  }

  /// Rounds of lease/release, so devices go back to the pool and get handed out
  /// again. Reuse is where a stale slot index or a botched reference count would
  /// surface as two tests sharing one device.
  func test_exclusive_leases_never_overlap_under_churn() async throws {
    let control = MockSimulatorControl()
    let manager = SimulatorManager(
      simulatorControl: control,
      // Keep released devices warm so they are reused rather than deleted, which
      // is the path that exercises slot reuse.
      deleteRecentlyUsedIdleAfter: 600,
      deleteIdleAfter: 600,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")
    let held = HeldDevices()

    for round in 0 ..< 4 {
      try await withThrowingTaskGroup(of: Void.self) { group in
        for offset in 0 ..< 8 {
          let pid = PID(20_000 + round * 100 + offset)
          group.addTask {
            let udid = try await manager.lease(to: pid, exclusive: true, config: config)
            await held.acquire(udid)

            // Hold across a suspension: an overlap is only observable if two
            // leases are live at once.
            try await Task.sleep(for: .milliseconds(5))

            // A device handed to a live lease must still exist. This is the
            // `No matching device` failure, caught at the moment it would happen.
            let deleted = await control.deletedSimulators
            XCTAssertFalse(
              deleted.contains(udid),
              "device \(udid) was deleted while PID \(pid) still held its lease"
            )

            await held.relinquish(udid)
            try await manager.release(for: pid)
          }
        }
        try await group.waitForAll()
      }
    }

    let overlaps = await held.overlaps
    XCTAssertTrue(
      overlaps.isEmpty,
      "exclusive leases overlapped on \(Set(overlaps).count) device(s): \(Set(overlaps))"
    )
  }

  /// Non-exclusive leases are *allowed* to share, but sharing must be bounded by
  /// reference counting: the device may only be retired once the last holder lets
  /// go. This is a shared-runner configuration.
  func test_shared_device_is_not_deleted_while_any_holder_remains() async throws {
    let control = MockSimulatorControl()
    let manager = SimulatorManager(
      simulatorControl: control,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let pids: [PID] = [31_001, 31_002, 31_003, 31_004]
    var devices: [PID: SimulatorUDID] = [:]
    for pid in pids {
      devices[pid] = try await manager.lease(to: pid, exclusive: false, config: config)
    }

    // Release all but the last, checking after each that the shared device stands.
    for pid in pids.dropLast() {
      try await manager.release(for: pid)

      let deleted = await control.deletedSimulators
      XCTAssertFalse(
        deleted.contains(devices[pids.last!]!),
        "the shared device was deleted while PID \(pids.last!) still held it"
      )
    }

    try await manager.release(for: pids.last!)
    let deleted = await control.deletedSimulators
    XCTAssertTrue(
      deleted.contains(devices[pids.last!]!),
      "the last release should retire the shared device"
    )
  }
}

/// Distinguishes the two ways a log can fill with
/// "doesn't have a simulator leased": lease-holder death, versus the daemon
/// losing its state. They are told apart by *which* actions warn, so the
/// signature is worth pinning.
///
/// These build managers with no `LeaseStore`, which is deliberate: they pin the
/// behavior of a daemon that cannot hand its leases over, both to describe
/// versions predating the handover and to keep the signature readable for anyone
/// diagnosing a log from one. `SimulatorManagerLeaseHandoverTests` covers what a
/// daemon with a store does instead.
final class SimulatorManagerWarningSignatureTests: XCTestCase {
  /// If the daemon loses state, every release warns -- including releases from
  /// tests that passed.
  func test_state_loss_makes_every_release_report_no_lease() async throws {
    let control = MockSimulatorControl()
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")
    let pids: [PID] = [41_001, 41_002, 41_003, 41_004]

    let before = SimulatorManager(
      simulatorControl: control,
      deleteRecentlyUsedIdleAfter: 600,
      deleteIdleAfter: 600,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
    for pid in pids {
      _ = try await before.lease(to: pid, exclusive: true, config: config)
    }

    // The daemon is replaced without releasing anything, as a crash or a
    // `kill -9` from start.sh's shutdown timeout would leave it.
    let after = SimulatorManager(
      simulatorControl: control,
      deleteRecentlyUsedIdleAfter: 600,
      deleteIdleAfter: 600,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )

    for pid in pids {
      // swiftformat:disable:next hoistAwait
      try await assertThrowsAsyncError(await after.release(for: pid)) { error in
        XCTAssertTrue(
          error is SimulatorManagerError,
          "expected a no-lease error for PID \(pid), got \(error)"
        )
      }
    }

    // None of those failed releases may delete a device: the devices survived the
    // restart and a live test could still be using one.
    let deleted = await control.deletedSimulators
    XCTAssertTrue(
      deleted.isEmpty,
      "releases against lost state must not delete devices, deleted: \(deleted)"
    )
  }

  /// The signature that distinguishes a mid-flight daemon restart from wholesale
  /// state loss: only the tests whose lease *predates* the restart warn on
  /// release. Tests that lease afterwards are unaffected.
  ///
  /// This matters because it is the only mechanism found so far that produces the
  /// warning on a subset of tests while the runner script is still alive. Total
  /// state loss makes every release warn, including releases from tests that
  /// passed, so it cannot explain a log where only some releases warn.
  func test_only_leases_predating_a_restart_report_no_lease() async throws {
    let control = MockSimulatorControl()
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")
    let before: [PID] = [42_001, 42_002]
    let after: [PID] = [42_003, 42_004]

    func makeManager() -> SimulatorManager {
      SimulatorManager(
        simulatorControl: control,
        deleteRecentlyUsedIdleAfter: 600,
        deleteIdleAfter: 600,
        recentlyUsedCapacity: 1,
        deleteOnPIDExit: false
      )
    }

    let oldDaemon = makeManager()
    for pid in before {
      _ = try await oldDaemon.lease(to: pid, exclusive: true, config: config)
    }

    // start.sh replaces the daemon when a concurrent action wants a different
    // version. The in-flight tests above are not told, and their runner scripts
    // keep running. Without a store there is nothing for the successor to read,
    // so their leases are gone -- which is the signature being pinned.
    let newDaemon = makeManager()
    for pid in after {
      _ = try await newDaemon.lease(to: pid, exclusive: true, config: config)
    }

    for pid in before {
      // swiftformat:disable:next hoistAwait
      try await assertThrowsAsyncError(await newDaemon.release(for: pid)) { error in
        XCTAssertTrue(
          error is SimulatorManagerError,
          "expected a no-lease error for pre-restart PID \(pid), got \(error)"
        )
      }
    }

    // The discriminating half: these must succeed. If they also threw, the
    // mechanism would be indistinguishable from total state loss.
    for pid in after {
      try await newDaemon.release(for: pid)
    }
  }

  /// A leaser that exits mid-provisioning must not strand its device. Stranding
  /// would shrink the usable pool for the life of the daemon, so later tests pile
  /// onto fewer and fewer devices.
  func test_leaser_exit_during_provisioning_does_not_strand_the_device() async throws {
    let control = MockSimulatorControl()
    let manager = SimulatorManager(
      simulatorControl: control,
      // Retire released devices at once, so a device that is *not* deleted here is
      // genuinely stranded rather than merely idle.
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: true
    )
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let deadLeaser = try spawnAndReapProcess()
    // swiftformat:disable:next hoistAwait
    await assertThrowsAsyncError(
      try await manager.lease(to: deadLeaser, exclusive: true, config: config)
    )

    // Whatever was provisioned before the exit was noticed must be accounted for:
    // either never created, or created and cleaned up. Site 1 of the liveness
    // check normally rejects a dead leaser before any clone exists, so record
    // which case this was rather than letting an empty set pass silently.
    let created = await control.baseForClones.keys
    let deleted = await control.deletedSimulators
    if created.isEmpty {
      let baseCalls = await control.createBaseCalls
      XCTAssertEqual(
        baseCalls,
        0,
        "a dead leaser should be rejected before provisioning starts, not midway"
      )
    }
    for clone in created {
      XCTAssertTrue(
        deleted.contains(clone),
        "clone \(clone) was provisioned for a dead leaser and never cleaned up"
      )
    }

    // The pool must still work afterwards.
    let recovered = try await manager.lease(to: PID(getpid()), exclusive: true, config: config)
    XCTAssertFalse(recovered.isEmpty)
  }
}

/// A daemon restart discards all in-memory lease state -- `start.sh` will
/// `kill -9` a daemon that does not stop within its shutdown timeout, and the
/// `/shutdown` endpoint does not release or delete leased devices either. The
/// devices themselves survive, so a fresh manager must recover them by name
/// rather than leaving them untracked forever.
final class SimulatorManagerRestartTests: XCTestCase {
  private func makeManager(_ control: MockSimulatorControl) -> SimulatorManager {
    SimulatorManager(
      simulatorControl: control,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
  }

  /// After a restart the new manager adopts the device left behind by the old
  /// one, instead of cloning a second device and orphaning the first.
  func test_restart_adopts_existing_device() async throws {
    let control = MockSimulatorControl()
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let before = try await makeManager(control)
      .lease(to: 1234, exclusive: true, config: config)

    // The old manager is discarded without releasing: its leases, slot map and
    // pending-deletion tasks are gone, but the device is still on the machine.
    let devicesAfterCrash = await control.devicesByName
    XCTAssertTrue(
      devicesAfterCrash.values.contains(before),
      "the leased device must outlive the manager"
    )

    let after = try await makeManager(control)
      .lease(to: 5678, exclusive: true, config: config)

    XCTAssertEqual(
      after,
      before,
      "a restarted manager should adopt the existing device, not orphan it"
    )
  }

  /// Releasing a lease the manager has no record of must fail rather than
  /// deleting a device another test may be using. This is the 404 the release
  /// hook gets when it runs after a restart.
  func test_restart_release_of_unknown_lease_throws() async throws {
    let control = MockSimulatorControl()
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    _ = try await makeManager(control).lease(to: 1234, exclusive: true, config: config)

    let restarted = makeManager(control)
    // swiftformat:disable:next hoistAwait
    try await assertThrowsAsyncError(await restarted.release(for: 1234))

    let deleted = await control.deletedSimulators
    XCTAssertTrue(
      deleted.isEmpty,
      "an unknown lease must not delete a device that may still be in use"
    )
  }
}

/// A `LeaseStore` held in memory, standing in for the file a real daemon writes.
///
/// Guarded by a lock rather than actor isolation: `LeaseStore` is synchronous, and
/// making the fake an actor would force `save` to defer its write, so a test could
/// observe the store before the write it just triggered had landed.
private final class FakeLeaseStore: LeaseStore, @unchecked Sendable {
  private let lock = NSLock()
  private var stored: [PersistedLease] = []

  /// Hands `load()` something the daemon never wrote, for the cases where the file
  /// is corrupt, hand-edited or written by another version.
  func preload(_ leases: [PersistedLease]) {
    lock.withLock { stored = leases }
  }

  func contents() -> [PersistedLease] {
    return lock.withLock { stored }
  }

  func save(_ leases: [PersistedLease]) {
    lock.withLock { stored = leases }
  }

  func load() -> [PersistedLease] {
    return contents()
  }
}

/// Leases are mirrored to disk so that a daemon replacing another can adopt the
/// ones whose tests are still running. Without that handover, `start.sh` -- which
/// runs before every lease and restarts on any version change -- silently dropped
/// the bookkeeping for in-flight tests, whose release then reported
/// "doesn't have a simulator leased".
final class SimulatorManagerLeaseHandoverTests: XCTestCase {
  private func makeManager(
    _ control: MockSimulatorControl,
    store: LeaseStore?,
    deleteOnPIDExit: Bool = false
  ) -> SimulatorManager {
    SimulatorManager(
      simulatorControl: control,
      deleteRecentlyUsedIdleAfter: 0,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: deleteOnPIDExit,
      leaseStore: store
    )
  }

  private let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

  /// The case from the bug: a live leaser's release must succeed against the
  /// daemon that replaced the one it leased from.
  func test_successor_honors_a_release_for_an_adopted_lease() async throws {
    let control = MockSimulatorControl()
    let store = FakeLeaseStore()

    // This process is by definition alive, so it stands in for a runner script
    // still running while the daemon underneath it is replaced.
    let leaser = getpid()
    let udid = try await makeManager(control, store: store)
      .lease(to: leaser, exclusive: true, config: config)

    let successor = makeManager(control, store: store)
    await successor.restoreLeases()

    // Would throw `noLease` -- the 404 behind the warning -- without the handover.
    try await successor.release(for: leaser)

    let deleted = await control.deletedSimulators
    XCTAssertEqual(
      deleted,
      [udid],
      "releasing an adopted lease should return its device, as a normal release does"
    )
  }

  /// A lease is only useful to a successor if it is on disk before the daemon
  /// dies, since `start.sh` escalates to `kill -9` and runs no cleanup.
  func test_a_lease_is_persisted_as_soon_as_it_is_granted() async throws {
    let control = MockSimulatorControl()
    let store = FakeLeaseStore()

    let udid = try await makeManager(control, store: store)
      .lease(to: 4242, exclusive: false, config: config)

    let persisted = store.contents()
    XCTAssertEqual(persisted.count, 1)
    XCTAssertEqual(persisted.first?.pid, 4242)
    XCTAssertEqual(persisted.first?.udid, udid)
    XCTAssertEqual(persisted.first?.config, config)
    XCTAssertEqual(persisted.first?.exclusive, false)
  }

  /// A lease whose process is gone must not be adopted: nobody is left to release
  /// it, so it would hold a device until the daemon restarted again.
  func test_a_dead_leasers_lease_is_not_adopted() async throws {
    let control = MockSimulatorControl()
    let store = FakeLeaseStore()

    // PID 1 is `launchd`: it is running but is certainly not our leaser, and its
    // start time will not match a fabricated one. That is the recycled-PID case.
    store.preload([
      .init(
        pid: 1,
        leaserStartTime: 999,
        udid: "DEAD-DEVICE",
        config: config,
        exclusive: true,
        slotIndex: 0
      ),
    ])

    let manager = makeManager(control, store: store)
    await manager.restoreLeases()

    let live = await manager.liveLeaseCount()
    XCTAssertEqual(live, 0, "a recycled PID must not inherit the original's lease")

    // swiftformat:disable:next hoistAwait
    try await assertThrowsAsyncError(await manager.release(for: 1))
  }

  /// The same PID with a matching start time is the original process, so its lease
  /// is adopted. Pairs with the test above: together they show the start-time check
  /// discriminates rather than rejecting everything.
  func test_a_live_leasers_lease_is_adopted() async throws {
    let control = MockSimulatorControl()
    let store = FakeLeaseStore()

    let leaser = getpid()
    store.preload([
      .init(
        pid: leaser,
        leaserStartTime: processStartTime(leaser),
        udid: "LIVE-DEVICE",
        config: config,
        exclusive: true,
        slotIndex: 0
      ),
    ])

    let manager = makeManager(control, store: store)
    await manager.restoreLeases()

    let live = await manager.liveLeaseCount()
    XCTAssertEqual(live, 1)
  }

  /// Dropped leases must not linger on disk, or a later restart would reconsider
  /// them after their PIDs had been recycled.
  func test_dropped_leases_are_removed_from_the_store() async throws {
    let control = MockSimulatorControl()
    let store = FakeLeaseStore()

    store.preload([
      .init(
        pid: 1,
        leaserStartTime: 999,
        udid: "DEAD-DEVICE",
        config: config,
        exclusive: true,
        slotIndex: 0
      ),
    ])

    await makeManager(control, store: store).restoreLeases()

    // The rewrite is asynchronous in the fake, so let the save land.
    try await Task.sleep(for: .milliseconds(100))
    let remaining = store.contents()
    XCTAssertTrue(remaining.isEmpty, "a dropped lease should not be reconsidered later")
  }

  /// Two leases claiming one exclusive device cannot both be true. Adopting both
  /// would hand the same simulator to two tests, so the conflict is dropped.
  func test_conflicting_exclusive_leases_are_not_both_adopted() async throws {
    let control = MockSimulatorControl()
    let store = FakeLeaseStore()

    let leaser = getpid()
    let start = processStartTime(leaser)
    store.preload([
      .init(
        pid: leaser,
        leaserStartTime: start,
        udid: "SHARED-DEVICE",
        config: config,
        exclusive: true,
        slotIndex: 0
      ),
      .init(
        pid: leaser,
        leaserStartTime: start,
        udid: "SHARED-DEVICE",
        config: config,
        exclusive: true,
        slotIndex: 1
      ),
    ])

    let manager = makeManager(control, store: store)
    await manager.restoreLeases()

    let live = await manager.liveLeaseCount()
    XCTAssertEqual(live, 1, "only one lease can hold an exclusive device")
  }

  /// Persistence is opt-in. Without a store the manager behaves as it always did,
  /// which is what the tests above this class rely on.
  func test_without_a_store_nothing_is_restored() async throws {
    let control = MockSimulatorControl()

    let leaser = getpid()
    _ = try await makeManager(control, store: nil)
      .lease(to: leaser, exclusive: true, config: config)

    let successor = makeManager(control, store: nil)
    await successor.restoreLeases()

    // swiftformat:disable:next hoistAwait
    try await assertThrowsAsyncError(await successor.release(for: leaser))
  }
}

/// A daemon that adopts a lease must also adopt the recency that decides how long
/// the device is kept warm once that lease is released.
///
/// Which of the two idle timers a released device gets is decided by whether its
/// config is in the recently-used set, and only `lease` puts it there. So a
/// successor starts with an empty set while holding adopted leases: the first
/// release lands on `delete-idle-after` -- 0 on a worker -- and the device is
/// destroyed instead of kept for the next test. The trigger is a version bump,
/// which is exactly when `start.sh` replaces a daemon holding live leases, so
/// raising the warm window is also what makes this worth fixing.
final class SimulatorManagerAdoptedRecencyTests: XCTestCase {
  /// The worker's shape, from `start.sh`: nothing is kept warm unless it is the
  /// recently-used config. A symmetric pair would hide the bug, since both
  /// branches would then keep the device.
  private func makeManager(
    _ control: MockSimulatorControl,
    store: LeaseStore?
  ) -> SimulatorManager {
    SimulatorManager(
      simulatorControl: control,
      deleteRecentlyUsedIdleAfter: 600,
      deleteIdleAfter: 0,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false,
      leaseStore: store
    )
  }

  private let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

  /// Deletion is scheduled on a task, so the assertions have to give it a chance to
  /// run. Generous against the deadline it would fire on (0s) and negligible
  /// against the one it must not (600s), so neither outcome is a matter of timing.
  private func letPendingDeletionRun() async throws {
    try await Task.sleep(for: .milliseconds(500))
  }

  /// The control: the same release, with no restart in the way. Pins that the warm
  /// window works at all, so the regression below can only be about adoption.
  func test_a_released_device_stays_warm_without_a_restart() async throws {
    let control = MockSimulatorControl()
    let manager = makeManager(control, store: FakeLeaseStore())

    let udid = try await manager.lease(to: getpid(), exclusive: true, config: config)
    try await manager.release(for: getpid())
    try await letPendingDeletionRun()

    let deleted = await control.deletedSimulators
    XCTAssertFalse(
      deleted.contains(udid),
      "precondition: a released device of the recently-used config is kept warm"
    )
  }

  /// The regression. A successor adopts the lease, its test finishes, and the
  /// device must be kept warm just as it would have been by the daemon that
  /// granted the lease.
  func test_an_adopted_lease_keeps_its_device_warm_on_release() async throws {
    let control = MockSimulatorControl()
    let store = FakeLeaseStore()

    // This process is alive by definition, so it stands in for a runner script
    // still running while the daemon underneath it is replaced.
    let leaser = getpid()
    let udid = try await makeManager(control, store: store)
      .lease(to: leaser, exclusive: true, config: config)

    let successor = makeManager(control, store: store)
    await successor.restoreLeases()

    try await successor.release(for: leaser)
    try await letPendingDeletionRun()

    let deleted = await control.deletedSimulators
    XCTAssertFalse(
      deleted.contains(udid),
      """
      an adopted lease's device was deleted on release rather than kept warm: \
      the successor did not inherit its config's recency, so the release took \
      the delete-idle-after branch
      """
    )
  }

  /// The consequence a test actually feels: the next lease reuses the warm device
  /// instead of paying a fresh clone and boot. Asserted separately from the
  /// deletion above because this is the cost, not the mechanism.
  func test_the_next_lease_reuses_an_adopted_leases_device() async throws {
    let control = MockSimulatorControl()
    let store = FakeLeaseStore()

    let leaser = getpid()
    let udid = try await makeManager(control, store: store)
      .lease(to: leaser, exclusive: true, config: config)

    let successor = makeManager(control, store: store)
    await successor.restoreLeases()
    try await successor.release(for: leaser)
    try await letPendingDeletionRun()

    let next = try await successor.lease(to: 5678, exclusive: true, config: config)
    XCTAssertEqual(
      next,
      udid,
      "the device left by an adopted lease should be reused, not re-cloned"
    )
  }
}

/// The on-disk format has to survive a real round trip, since a successor daemon
/// is a different process reading what this one wrote.
final class FileLeaseStoreTests: XCTestCase {
  private func temporaryPath() -> String {
    return FileManager.default.temporaryDirectory
      .appendingPathComponent("leases-\(UUID().uuidString).json")
      .path
  }

  func test_leases_round_trip_through_a_file() throws {
    let path = temporaryPath()
    defer { try? FileManager.default.removeItem(atPath: path) }

    let store = FileLeaseStore(path: path)
    let leases: [PersistedLease] = [
      .init(
        pid: 501,
        leaserStartTime: 1234,
        udid: "UDID-A",
        config: .init(deviceType: "iPhone 16", os: "iOS", version: "26.4"),
        exclusive: true,
        slotIndex: 0
      ),
      .init(
        pid: 502,
        leaserStartTime: nil,
        udid: "UDID-B",
        config: .init(deviceType: "iPad", os: "iOS", version: "18.0"),
        exclusive: false,
        slotIndex: 3
      ),
    ]

    store.save(leases)

    XCTAssertEqual(FileLeaseStore(path: path).load(), leases)
  }

  /// A missing file is the first-ever start, not an error.
  func test_a_missing_file_loads_as_empty() {
    XCTAssertEqual(FileLeaseStore(path: temporaryPath()).load(), [])
  }

  /// A corrupt file must not stop the daemon from starting; the worst case is the
  /// old behavior, where leases predating the restart are unknown.
  func test_a_corrupt_file_loads_as_empty() throws {
    let path = temporaryPath()
    defer { try? FileManager.default.removeItem(atPath: path) }

    try "not json".write(toFile: path, atomically: true, encoding: .utf8)

    XCTAssertEqual(FileLeaseStore(path: path).load(), [])
  }

  /// Saving replaces rather than appends, so a released lease does not come back.
  func test_saving_replaces_the_previous_contents() {
    let path = temporaryPath()
    defer { try? FileManager.default.removeItem(atPath: path) }

    let store = FileLeaseStore(path: path)
    store.save([
      .init(
        pid: 1,
        leaserStartTime: nil,
        udid: "OLD",
        config: .init(deviceType: "iPhone 16", os: "iOS", version: "26.4"),
        exclusive: true,
        slotIndex: 0
      ),
    ])
    store.save([])

    XCTAssertEqual(store.load(), [])
  }

  /// A save leaves only the lease file behind. `.atomic` already writes via an
  /// auxiliary file and renames it into place, so doing that by hand here would be
  /// redundant -- and would strand a file of our own naming if the daemon died
  /// between the write and the rename.
  func test_saving_leaves_no_other_files_behind() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("lease-store-\(UUID().uuidString)")
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: directory) }

    let name = "leases.json"
    let store = FileLeaseStore(path: directory.appendingPathComponent(name).path)
    store.save([
      .init(
        pid: 1,
        leaserStartTime: nil,
        udid: "UDID-A",
        config: .init(deviceType: "iPhone 16", os: "iOS", version: "26.4"),
        exclusive: true,
        slotIndex: 0
      ),
    ])
    // Twice, since the interesting case is overwriting an existing file.
    store.save([])

    let contents = try FileManager.default.contentsOfDirectory(atPath: directory.path)
    XCTAssertEqual(contents, [name])
  }
}

/// `simctl` can report a device as invalid -- deleted out from under us, or
/// corrupt after the machine was under load. The manager recovers by discarding
/// that device and returning a fresh one, rather than handing the caller a UDID
/// that will fail at launch with "No matching device".
final class SimulatorManagerInvalidDeviceTests: XCTestCase {
  private func makeManager(_ control: MockSimulatorControl) -> SimulatorManager {
    SimulatorManager(
      simulatorControl: control,
      // Keep released clones around so the second lease reuses the first device
      // and has to boot it again -- that is the path that detects invalidity.
      deleteRecentlyUsedIdleAfter: 600,
      deleteIdleAfter: 600,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
  }

  /// Exit code 148 is "Invalid device". Reusing such a device must replace it.
  func test_reuse_of_invalid_device_returns_a_different_device() async throws {
    let control = MockSimulatorControl()
    let manager = makeManager(control)
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let first = try await manager.lease(to: 1234, exclusive: true, config: config)
    try await manager.release(for: 1234)

    // The device goes bad while idle, the way a simulator can be lost when
    // CoreSimulatorService is under pressure.
    await control.failNextBoot(of: first, exitCode: 148)

    let second = try await manager.lease(to: 5678, exclusive: true, config: config)

    XCTAssertNotEqual(
      second,
      first,
      "an invalid device must be replaced, not handed back to the caller"
    )
    let deleted = await control.deletedSimulators
    XCTAssertTrue(deleted.contains(first), "the invalid device should be deleted")
  }

  /// Any other exit code is not a known-recoverable condition, so it propagates
  /// instead of silently churning devices.
  func test_reuse_propagates_unrecognised_boot_failure() async throws {
    let control = MockSimulatorControl()
    let manager = makeManager(control)
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let first = try await manager.lease(to: 1234, exclusive: true, config: config)
    try await manager.release(for: 1234)

    await control.failNextBoot(of: first, exitCode: 1)

    // swiftformat:disable:next hoistAwait
    await assertThrowsAsyncError(
      try await manager.lease(to: 5678, exclusive: true, config: config)
    ) { error in
      XCTAssertEqual((error as? ProcessError)?.exitCode, 1)
    }
  }
}

/// `getBase` caches the in-flight base-creation task so concurrent leases share
/// one device rather than racing to create several.
final class SimulatorManagerBaseTaskTests: XCTestCase {
  private func makeManager(_ control: MockSimulatorControl) -> SimulatorManager {
    SimulatorManager(
      simulatorControl: control,
      deleteRecentlyUsedIdleAfter: 600,
      deleteIdleAfter: 600,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
  }

  /// A failed base creation must not poison the cache: the next lease has to try
  /// again rather than await the failed task forever, or every subsequent test on
  /// the worker would fail for the life of the daemon.
  func test_failed_base_creation_does_not_poison_the_cache() async throws {
    let control = MockSimulatorControl()
    let manager = makeManager(control)
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    await control.setFailNextCreateBase()

    // swiftformat:disable:next hoistAwait
    try await assertThrowsAsyncError(
      await manager.lease(to: 1234, exclusive: true, config: config)
    )

    // The retry must reach `createBase` again and succeed.
    let recovered = try await manager.lease(to: 5678, exclusive: true, config: config)
    XCTAssertFalse(recovered.isEmpty)

    let calls = await control.createBaseCalls
    XCTAssertEqual(calls, 2, "the second lease must retry base creation")
  }

  /// Concurrent leases for the same configuration share one base simulator.
  func test_concurrent_leases_share_one_base() async throws {
    let control = MockSimulatorControl()
    let manager = makeManager(control)
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    // Fire several exclusive leases at once. Each needs its own clone, but all
    // clones must come from a single base.
    let leased = try await withThrowingTaskGroup(of: SimulatorUDID.self) { group in
      for pid in PID(9000) ..< PID(9004) {
        group.addTask {
          try await manager.lease(to: pid, exclusive: true, config: config)
        }
      }

      var results: [SimulatorUDID] = []
      for try await udid in group {
        results.append(udid)
      }
      return results
    }

    XCTAssertEqual(Set(leased).count, 4, "exclusive leases must not share a device")

    let bases = await control.baseSimulators[config] ?? []
    XCTAssertEqual(bases.count, 1, "all clones should come from one base simulator")

    let baseForClones = await control.baseForClones
    for clone in leased {
      XCTAssertEqual(baseForClones[clone], bases.first)
    }
  }
}

/// A device whose deletion timer is running can still be leased: the lease
/// cancels the timer. If that hand-off were lost, a test would be handed a UDID
/// that a pending deletion then removed -- the "No matching device" failure.
final class SimulatorManagerPendingDeletionTests: XCTestCase {
  func test_lease_during_pending_deletion_keeps_the_device() async throws {
    let control = MockSimulatorControl()
    // A one-second window: long enough to lease into, short enough that the test
    // can outlive it and prove the timer was cancelled rather than merely slow.
    let manager = SimulatorManager(
      simulatorControl: control,
      deleteRecentlyUsedIdleAfter: 1,
      deleteIdleAfter: 1,
      recentlyUsedCapacity: 1,
      deleteOnPIDExit: false
    )
    let config = SimulatorConfig(deviceType: "iPhone 14", os: "iOS", version: "16.4")

    let first = try await manager.lease(to: 1234, exclusive: true, config: config)
    try await manager.release(for: 1234)

    // Claim it back while the deletion is still pending.
    let second = try await manager.lease(to: 5678, exclusive: true, config: config)
    XCTAssertEqual(second, first, "the pending deletion should be reclaimed")

    // Outlive the original deadline. The device must still be ours.
    //
    // This is a real sleep against a real deadline, so it is the one timing-
    // dependent test here: the margin is 1s of slack against a 1s window, and a
    // heavily loaded machine could in principle narrow that. Widen both values
    // rather than removing the wait, since the point is to outlive the deadline.
    try await Task.sleep(for: .seconds(2))

    let deleted = await control.deletedSimulators
    XCTAssertFalse(
      deleted.contains(first),
      "leasing a device must cancel its pending deletion, not merely delay it"
    )
  }
}

final class LRUSetTests: XCTestCase {
  /// With capacity 1, leasing a second configuration evicts the first -- which
  /// flips the first config's released devices from `delete-recently-used-idle-after`
  /// to `delete-idle-after`. On a worker configured 0/60 that means devices for
  /// any config other than the most recent are deleted immediately on release, so
  /// a repo testing more than `recently-used-capacity` configurations never gets
  /// a warm device.
  func test_capacity_one_evicts_previous_config() {
    var set = LRUSet<String>(capacity: 1)

    XCTAssertNil(set.insert("iPhone 11_26.5"))
    XCTAssertTrue(set.contains("iPhone 11_26.5"))

    let evicted = set.insert("iPad Air_26.5")
    XCTAssertEqual(evicted, "iPhone 11_26.5")
    XCTAssertFalse(
      set.contains("iPhone 11_26.5"),
      "the evicted config now takes the short idle timer"
    )
    XCTAssertTrue(set.contains("iPad Air_26.5"))
  }

  /// Raising the capacity keeps both configurations warm.
  func test_capacity_two_keeps_both_configs() {
    var set = LRUSet<String>(capacity: 2)

    XCTAssertNil(set.insert("iPhone 11_26.5"))
    XCTAssertNil(set.insert("iPad Air_26.5"))

    XCTAssertTrue(set.contains("iPhone 11_26.5"))
    XCTAssertTrue(set.contains("iPad Air_26.5"))

    // A third config evicts the least recently used, not the most recent.
    XCTAssertEqual(set.insert("iPhone 17_26.5"), "iPhone 11_26.5")
    XCTAssertTrue(set.contains("iPad Air_26.5"))
    XCTAssertTrue(set.contains("iPhone 17_26.5"))
  }

  /// Re-inserting an existing element must refresh its recency without evicting
  /// anything. `insert` reports the element it removed from the ordering array,
  /// which for a re-insert is the element itself -- callers must not treat that
  /// as an eviction.
  func test_reinsert_does_not_evict() {
    var set = LRUSet<String>(capacity: 2)

    _ = set.insert("a")
    _ = set.insert("b")

    // Re-inserting "a" makes it most recent; "b" must stay.
    _ = set.insert("a")
    XCTAssertTrue(set.contains("a"))
    XCTAssertTrue(set.contains("b"))

    // So a third insert evicts "b", the genuinely least recently used.
    XCTAssertEqual(set.insert("c"), "b")
    XCTAssertFalse(set.contains("b"))
    XCTAssertTrue(set.contains("a"))
  }
}

/// Returns the PID of a process that has exited, so `kill(pid, 0)` fails.
private func spawnAndReapProcess() throws -> PID {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/true")
  try process.run()
  process.waitUntilExit()
  return PID(process.processIdentifier)
}

func assertThrowsAsyncError(
  _ expression: @autoclosure () async throws -> some Any,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line,
  _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
  do {
    _ = try await expression()
    // expected error to be thrown, but it was not
    let customMessage = message()
    if customMessage.isEmpty {
      XCTFail("Asynchronous call did not throw an error.", file: file, line: line)
    } else {
      XCTFail(customMessage, file: file, line: line)
    }
  } catch {
    errorHandler(error)
  }
}

actor MockSimulatorControl: SimulatorControl {
  var baseSimulators: [SimulatorConfig: [SimulatorUDID]] = [:]
  var baseForClones: [SimulatorUDID: SimulatorUDID] = [:]

  /// Devices that exist as far as `simctl` is concerned, keyed by name. Survives
  /// a `SimulatorManager` being discarded, the way real devices survive a daemon
  /// restart.
  var devicesByName: [String: SimulatorUDID] = [:]
  var deletedSimulators: [SimulatorUDID] = []

  func createBase(
    name: String,
    with config: SimulatorConfig,
    runtimeIdentifier: String
  ) async throws -> SimulatorUDID {
    createBaseCalls += 1

    if failNextCreateBase {
      failNextCreateBase = false
      throw ProcessError(
        command: "xcrun simctl create \(name)",
        context: "createBase",
        exitCode: 149,
        stdOut: "",
        stdErr: "Invalid runtime"
      )
    }

    let simulator = UUID().uuidString
    baseSimulators[config, default: []].append(simulator)
    devicesByName[name] = simulator
    return simulator
  }

  func clone(
    _ simulator: SimulatorUDID,
    name: String,
    deviceType: String,
    runtimeIdentifier: String,
    postBoot: String?
  ) async throws -> SimulatorUDID {
    // Mirrors the real implementation, which looks for an existing device of this
    // name first so that a clone left behind by a killed manager is adopted rather
    // than duplicated.
    if let existing = devicesByName[name] {
      return existing
    }

    let clone = UUID().uuidString
    baseForClones[clone] = simulator
    devicesByName[name] = clone
    return clone
  }

  /// UDIDs whose next `ensureBooted` should fail, and the exit code to fail with.
  /// Consumed on use, so a retry against a fresh device succeeds.
  var bootFailures: [SimulatorUDID: Int32] = [:]
  var ensureBootedCalls: [SimulatorUDID] = []

  /// When set, the next `createBase` throws instead of creating a device.
  var failNextCreateBase = false
  var createBaseCalls = 0

  func setFailNextCreateBase() {
    failNextCreateBase = true
  }

  func failNextBoot(of simulator: SimulatorUDID, exitCode: Int32) {
    bootFailures[simulator] = exitCode
  }

  func ensureBooted(
    _ simulator: SimulatorUDID,
    context: @escaping @autoclosure () -> String?
  ) async throws {
    ensureBootedCalls.append(simulator)

    if let exitCode = bootFailures.removeValue(forKey: simulator) {
      throw ProcessError(
        command: "xcrun simctl bootstatus \(simulator) -b",
        context: context(),
        exitCode: exitCode,
        stdOut: "",
        stdErr: "An error was encountered processing the command (domain=com.apple.CoreSimulator.SimError, code=148)"
      )
    }
  }

  func cleanTempFiles(in simulator: SimulatorUDID) {
    return
  }

  func delete(
    _ simulator: SimulatorUDID,
    name: String,
    context: @escaping @autoclosure () -> String?
  ) async throws {
    deletedSimulators.append(simulator)
    if devicesByName[name] == simulator {
      devicesByName.removeValue(forKey: name)
    }
  }

  func getExisting(
    name: String,
    deviceType: String,
    runtimeIdentifier: String,
    context: @escaping @autoclosure () -> String?
  ) async throws -> String? {
    return devicesByName[name]
  }
}
