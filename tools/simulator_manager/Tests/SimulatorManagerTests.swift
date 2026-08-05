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

  func createBase(
    name: String,
    with config: SimulatorConfig,
    runtimeIdentifier: String
  ) async throws -> SimulatorUDID {
    let simulator = UUID().uuidString
    baseSimulators[config, default: []].append(simulator)
    return simulator
  }

  func clone(
    _ simulator: SimulatorUDID,
    name: String,
    deviceType: String,
    runtimeIdentifier: String,
    postBoot: String?
  ) async throws -> SimulatorUDID {
    let clone = UUID().uuidString
    baseForClones[clone] = simulator
    return clone
  }

  func ensureBooted(
    _ simulator: SimulatorUDID,
    context: @escaping @autoclosure () -> String?
  ) async throws {
    return
  }

  func cleanTempFiles(in simulator: SimulatorUDID) {
    return
  }

  func delete(
    _ simulator: SimulatorUDID,
    name: String,
    context: @escaping @autoclosure () -> String?
  ) async throws {
    return
  }

  func getExisting(
    name: String,
    deviceType: String,
    runtimeIdentifier: String,
    context: @escaping @autoclosure () -> String?
  ) async throws -> String? {
    return nil
  }
}
