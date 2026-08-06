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
