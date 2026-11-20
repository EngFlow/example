import Foundation
import os

typealias PID = pid_t

extension Logger {
  static let simulatorManager = simulatorManager(category: "manager")
}

enum SimulatorManagerError: Error {
  case alreadyLeased(udid: SimulatorUDID)
  case noLease
  case leaserExited
}

private struct SimulatorLease {
  let udid: SimulatorUDID
  let config: SimulatorConfig
  let exclusive: Bool
  let slotIndex: Int
  /// When the leasing process started, captured at lease time.
  ///
  /// Persisted so a successor daemon can tell a still-running leaser from a
  /// recycled PID. Nil when it could not be read.
  let leaserStartTime: UInt64?
}

/// Whether `pid` is still running.
///
/// `kill(pid, 0)` reports failure for two unrelated reasons, and only one of them
/// means the process is gone: `ESRCH` (no such process) versus `EPERM` (it exists
/// but we may not signal it). Treating `EPERM` as death would release a live
/// leaser's device out from under it, so only `ESRCH` counts.
func processIsRunning(_ pid: PID) -> Bool {
  if kill(pid, 0) == 0 {
    return true
  }
  return errno != ESRCH
}

private enum SimulatorSlot {
  case empty
  case pendingCreation(Task<SimulatorUDID, Error>, exclusive: Bool)
  case active(SimulatorUDID, exclusive: Bool)
  case pendingDeletion(SimulatorUDID, Task<Void, Error>)
  case deleting(SimulatorUDID)
}

extension SimulatorSlot {
  var sortOrder: Int {
    switch self {
    // Try to use active or pending creation simulators first (should only be
    // one of either for non-exclusive)
    case .active:
      return 0
    case .pendingCreation:
      return 1

    // Use a pending deletion before any empty slots
    case .pendingDeletion:
      return 2

    // Finally use empty slots
    case .empty:
      return 3

    // Deleting simulator can't be used, so put it at the end
    case .deleting:
      return 4
    }
  }
}

private enum SimulatorSlotResult {
  case active(SimulatorUDID, slotIndex: Int)
  case pending(Task<SimulatorUDID, Error>, slotIndex: Int)
}

actor SimulatorManager {
  private let simulatorControl: SimulatorControl

  private var simulatorSlots: [SimulatorConfig: [SimulatorSlot]] = [:]
  private var referenceCount: [SimulatorUDID: Int] = [:]
  private var leases: [PID: SimulatorLease] = [:]

  private var leaserExitListeners: [PID: DispatchSourceProcess] = [:]

  private var getBaseSimulatorTasks: [SimulatorConfig: Task<SimulatorUDID, Error>] = [:]

  private let deleteIdleAfter: UInt16
  private let deleteRecentlyUsedIdleAfter: UInt16
  private let deleteOnPIDExit: Bool

  /// Where leases are mirrored so a successor daemon can adopt them. Nil disables
  /// persistence, which is the default in tests that do not care about it.
  private let leaseStore: LeaseStore?

  private var recentlyLeased: LRUSet<SimulatorConfig>

  private var postBoot: String?

  init(
    simulatorControl: SimulatorControl,
    deleteRecentlyUsedIdleAfter: UInt16,
    deleteIdleAfter: UInt16,
    recentlyUsedCapacity: Int,
    deleteOnPIDExit: Bool,
    postBoot: String? = nil,
    leaseStore: LeaseStore? = nil
  ) {
    self.simulatorControl = simulatorControl
    self.deleteIdleAfter = deleteIdleAfter
    self.deleteRecentlyUsedIdleAfter = deleteRecentlyUsedIdleAfter
    self.deleteOnPIDExit = deleteOnPIDExit
    self.recentlyLeased = LRUSet(capacity: recentlyUsedCapacity)
    self.postBoot = postBoot
    self.leaseStore = leaseStore

    // Change the working directory to some place stable, since on RBE the runfiles directory can
    // get cleaned up
    FileManager.default.changeCurrentDirectoryPath("/tmp")
  }

  /// Adopts the leases and idle simulators a previous daemon left behind.
  ///
  /// Leases used to live only in this actor's memory, so replacing the daemon --
  /// which `start.sh` does on any version change, on every lease -- lost the
  /// bookkeeping for tests that were still running. Their release calls then
  /// reached a daemon that had never heard of them and reported "doesn't have a
  /// simulator leased".
  ///
  /// Restoring rebuilds enough state for `release` to work: the lease itself, the
  /// slot holding the device, a reference count, and an exit listener so a leaser
  /// that dies during the handover is still cleaned up.
  ///
  /// Every other device the previous daemon knew about -- those it was keeping
  /// warm, and those of leases that can't be adopted -- goes back on an idle
  /// timer, as if just released. Left alone, nothing would ever delete them: they
  /// are only picked up again if a later lease happens to clone into that exact
  /// slot.
  func restoreLeases() async {
    guard let leaseStore else { return }

    let persisted = leaseStore.load()
    guard !persisted.leases.isEmpty || !persisted.idleSimulators.isEmpty else { return }

    // The previous daemon kept these warm because their configs were recently
    // leased, so carry that over; otherwise on a worker, where `deleteIdleAfter`
    // is 0, every restart would delete them immediately. Inserted before adopting
    // leases so the configs of running tests end up most recent.
    for idle in persisted.idleSimulators {
      recentlyLeased.insert(idle.config)
    }

    var adopted = 0
    var dropped = 0
    var unowned = persisted.idleSimulators

    for lease in persisted.leases {
      guard leaserSurvived(lease) else {
        dropped += 1
        unowned.append(.init(udid: lease.udid, config: lease.config, slotIndex: lease.slotIndex))
        continue
      }

      // Two leases cannot share an exclusive device, and a slot cannot hold two
      // different devices. A file that says otherwise is inconsistent -- possibly
      // hand-edited, or written by a version with different slot semantics -- so
      // prefer dropping the lease over corrupting the slot bookkeeping.
      guard canAdopt(lease) else {
        Logger.simulatorManager.error(
          """
          ❌ Not restoring conflicting lease for PID \(lease.pid, privacy: .public) \
          on \(lease.udid, privacy: .public)
          """
        )
        dropped += 1
        unowned.append(.init(udid: lease.udid, config: lease.config, slotIndex: lease.slotIndex))
        continue
      }

      leases[lease.pid] = .init(
        udid: lease.udid,
        config: lease.config,
        exclusive: lease.exclusive,
        slotIndex: lease.slotIndex,
        leaserStartTime: lease.leaserStartTime
      )

      // Recreate the slot the device occupies, so it is neither handed to an
      // incompatible lease nor deleted as idle while its owner is still running.
      var slots = simulatorSlots[lease.config] ?? []
      while slots.count <= lease.slotIndex {
        slots.append(.empty)
      }
      slots[lease.slotIndex] = .active(lease.udid, exclusive: lease.exclusive)
      simulatorSlots[lease.config] = slots

      // Adopting the lease is not enough: how long this device is kept warm once
      // released is decided by whether its config is recently used, and only
      // `lease` records that. Without this the first release after a restart takes
      // `deleteIdleAfter` -- 0 on a worker -- and deletes a device the daemon we
      // replaced would have kept, making every version bump cost the tests in
      // flight a fresh boot.
      recentlyLeased.insert(lease.config)

      incrementReferenceCount(for: lease.udid)

      if deleteOnPIDExit {
        registerReleaseOnExit(for: lease.pid)
      }

      adopted += 1
    }

    var reclaimed = Set<SimulatorUDID>()
    for idle in unowned {
      // Skip a device an adopted lease still holds (a dropped lease can share a
      // non-exclusive device with one that survived), or one already reclaimed.
      guard referenceCount[idle.udid] == nil, reclaimed.insert(idle.udid).inserted else {
        continue
      }

      await reclaim(idle)
    }

    Logger.simulatorManager.info(
      """
      ♻️ Restored \(adopted, privacy: .public) lease(s) from a previous simulator \
      manager; dropped \(dropped, privacy: .public) stale or conflicting lease(s); \
      put \(reclaimed.count, privacy: .public) unowned simulator(s) on an idle timer
      """
    )

    // The dropped entries are gone for good, so rewrite the file rather than let a
    // later crash re-adopt them.
    persistState()
  }

  /// Puts a simulator the previous daemon left unowned back on an idle timer in
  /// its slot, or deletes it outright if an adopted lease has taken that slot.
  private func reclaim(_ idle: PersistedIdleSimulator) async {
    var slots = simulatorSlots[idle.config] ?? []
    while slots.count <= idle.slotIndex {
      slots.append(.empty)
    }
    simulatorSlots[idle.config] = slots

    guard case .empty = slots[idle.slotIndex] else {
      Logger.simulatorManager.warning(
        """
        ⚠️ Deleting unowned simulator \(idle.udid, privacy: .public), whose slot is \
        already taken
        """
      )
      // If we fail to delete, don't throw an error
      try? await simulatorControl.delete(
        idle.udid,
        name: idle.config.cloneDeviceName(index: idle.slotIndex),
        context: "restoreLeases, slot taken"
      )
      return
    }

    await pendingDeletion(idle.udid, config: idle.config, slotIndex: idle.slotIndex)
  }

  /// Whether the process that took `lease` is the one still running under that
  /// PID, rather than an unrelated process that reused the number.
  private func leaserSurvived(_ lease: PersistedLease) -> Bool {
    guard processIsRunning(lease.pid) else { return false }

    // A record without a start time predates that field. Fall back to liveness
    // alone: adopting on a PID collision costs one device held until that process
    // exits, which is better than dropping every lease on a mixed-version upgrade.
    guard let persistedStart = lease.leaserStartTime else { return true }

    guard let currentStart = processStartTime(lease.pid) else { return false }

    guard currentStart == persistedStart else {
      Logger.simulatorManager.info(
        """
        👻 PID \(lease.pid, privacy: .public) is running but started at a different \
        time than the lease recorded; treating the leaser as exited
        """
      )
      return false
    }

    return true
  }

  /// Whether `lease` can be adopted without contradicting one already restored.
  private func canAdopt(_ lease: PersistedLease) -> Bool {
    for existing in leases.values {
      if existing.udid == lease.udid, existing.exclusive || lease.exclusive {
        return false
      }

      if existing.config == lease.config,
         existing.slotIndex == lease.slotIndex,
         existing.udid != lease.udid {
        return false
      }
    }

    return true
  }

  /// Mirrors the current leases and idle simulators to disk.
  ///
  /// Called on every change rather than at shutdown, because the daemon is not
  /// always shut down politely: `start.sh` escalates to `kill -9`, which runs no
  /// cleanup. Each change costs a small JSON write, against provisioning a
  /// simulator that takes seconds.
  private func persistState() {
    guard let leaseStore else { return }

    // Includes devices mid-deletion, so one whose delete a `kill -9` interrupts is
    // still cleaned up by the successor.
    var idleSimulators: [PersistedIdleSimulator] = []
    for (config, slots) in simulatorSlots {
      for (slotIndex, slot) in slots.enumerated() {
        switch slot {
        case .pendingDeletion(let udid, _), .deleting(let udid):
          idleSimulators.append(.init(udid: udid, config: config, slotIndex: slotIndex))
        case .empty, .pendingCreation, .active:
          break
        }
      }
    }

    leaseStore.save(
      .init(
        leases: leases.map { pid, lease in
          .init(
            pid: pid,
            leaserStartTime: lease.leaserStartTime,
            udid: lease.udid,
            config: lease.config,
            exclusive: lease.exclusive,
            slotIndex: lease.slotIndex
          )
        },
        idleSimulators: idleSimulators
      )
    )
  }

  func lease(
    to leaser: PID,
    exclusive: Bool,
    config: SimulatorConfig
  ) async throws -> SimulatorUDID {
    // Each process can only lease one simulator at a time
    if let existingLease = leases[leaser] {
      throw SimulatorManagerError.alreadyLeased(udid: existingLease.udid)
    }

    Logger.simulatorManager.info(
      """
      🔒 Leasing \(exclusive ? "exclusive" : "non-exclusive", privacy: .public) \
      \(config, privacy: .public) simulator for PID \(leaser, privacy: .public)
      """
    )

    // Check liveness before provisioning rather than after. `getSimulator()` can
    // await for minutes while it clones, boots and runs the post-boot script, and
    // a leaser that dies during that window (e.g. killed by its build tool's test
    // timeout while queued for a simulator) used to be detected only afterwards --
    // releasing the lease a millisecond after granting it, and deleting the device
    // out from under a test that had already been handed the UDID.
    //
    // Only meaningful when we track leaser exit at all; otherwise the caller owns
    // the lease lifetime and the PID need not be a live process.
    if deleteOnPIDExit, !processIsRunning(leaser) {
      Logger.simulatorManager.info(
        "👋 PID \(leaser, privacy: .public) exited before its lease could be provisioned"
      )
      throw SimulatorManagerError.leaserExited
    }

    // `getSimulator()` will increment the reference count for the simulator
    let (simulator, slotIndex) = try await getSimulator(for: config, exclusive: exclusive)

    recentlyLeased.insert(config)

    // Re-check now that provisioning is done: the leaser may have exited while we
    // were cloning and booting. Record the lease first so `release` can unwind the
    // reference count and put the device back in the idle pool, then hand it back
    // rather than returning a UDID nobody will use.
    leases[leaser] = .init(
      udid: simulator,
      config: config,
      exclusive: exclusive,
      slotIndex: slotIndex,
      leaserStartTime: processStartTime(leaser)
    )
    persistState()

    if deleteOnPIDExit, !processIsRunning(leaser) {
      Logger.simulatorManager.info(
        """
        👋 PID \(leaser, privacy: .public) exited while its simulator was being \
        provisioned; returning \(simulator, privacy: .public) to the pool
        """
      )
      try await release(for: leaser)
      throw SimulatorManagerError.leaserExited
    }

    Logger.simulatorManager.info(
      "🔒 Leased simulator \(simulator, privacy: .public) to PID \(leaser, privacy: .public)"
    )

    if deleteOnPIDExit {
      registerReleaseOnExit(for: leaser)
    }

    return simulator
  }

  /// The number of leases whose leasing process is still running.
  ///
  /// Exposed over HTTP for diagnostics -- "was anything actually leased when this
  /// daemon was replaced?" is otherwise hard to answer after the fact. Leases held
  /// by exited processes are excluded, since those are already reclaimed or about
  /// to be.
  func liveLeaseCount() -> Int {
    return leases.keys.count(where: { processIsRunning($0) })
  }

  func release(for leaser: PID) async throws {
    guard let lease = leases.removeValue(forKey: leaser) else {
      // If the manager recently restarted, we might not have the state of all leases. Since
      // `SimulatorControl` will return existing simulators matching a given name, the dangling
      // simulator will eventually get picked back up again and properly reference counted. So we
      // will return an error here, and ignore it in the test runner.
      throw SimulatorManagerError.noLease
    }

    Logger.simulatorManager.info(
      "🔓 Releasing simulator \(lease.udid, privacy: .public) for PID \(leaser, privacy: .public)"
    )

    // Recorded before the device is torn down, so a daemon replaced mid-release
    // does not adopt a lease whose simulator is already going away.
    persistState()

    removeReleaseOnExit(for: leaser)

    await simulatorControl.cleanTempFiles(in: lease.udid)

    await decrementReferenceCount(
      for: lease.udid,
      config: lease.config,
      slotIndex: lease.slotIndex
    )
  }

  private func getBase(
    for config: SimulatorConfig
  ) async throws -> SimulatorUDID {
    if let existingTask = getBaseSimulatorTasks[config] {
      return try await existingTask.value
    }

    // We use a task to prevent data races that can occur when the `await` on `simulatorControl`
    // blocks. This ensures that multiple callers trying to get a base simulator will all wait
    // for the same simulator to be returned.
    let task = Task<SimulatorUDID, Error> {
      defer {
        getBaseSimulatorTasks.removeValue(forKey: config)
      }

      Logger.simulatorManager.info("📱 Creating \(config, privacy: .public) base simulator")

      let baseSimulator =
        try await simulatorControl
          .createBase(
            name: config.baseDeviceName(),
            with: config,
            runtimeIdentifier: config.runtimeIdentifier()
          )

      Logger.simulatorManager.info(
        "📱 Created \(config, privacy: .public) base simulator: \(baseSimulator, privacy: .public)"
      )

      return baseSimulator
    }

    getBaseSimulatorTasks[config] = task

    return try await task.value
  }

  private func incrementReferenceCount(for simulator: SimulatorUDID) {
    var count = referenceCount[simulator] ?? 0
    count += 1
    referenceCount[simulator] = count

    Logger.simulatorManager.debug(
      """
      🔼 Reference count for simulator \(simulator, privacy: .public) is now \
      \(count, privacy: .public)
      """
    )
  }

  private func decrementReferenceCount(
    for simulator: SimulatorUDID,
    config: SimulatorConfig,
    slotIndex: Int
  ) async {
    guard var count = referenceCount[simulator] else {
      // Simulator was already deleted, nothing to do
      return
    }

    count -= 1
    referenceCount[simulator] = count

    Logger.simulatorManager.debug(
      "🔽 Reference count for \(simulator, privacy: .public) is now \(count, privacy: .public)"
    )

    guard count == 0 else {
      return
    }

    // Wait a bit before deleting simulators, to allow them to be reused
    await pendingDeletion(simulator, config: config, slotIndex: slotIndex)
  }

  // Warning: We must update slots before we `await` on anything in this function (unless that
  // method updates slots before `await`ing on anything).
  private func getSimulator(
    for config: SimulatorConfig,
    exclusive: Bool
  ) async throws -> (simulator: SimulatorUDID, slotIndex: Int) {
    if simulatorSlots.keys.contains(config) == false {
      simulatorSlots[config] = []
    }

    // Need to sort so we reuse the the correct slots
    let sortedSlots = simulatorSlots[config]!.enumerated().sorted { lhs, rhs in
      let lhsSortOrder = lhs.element.sortOrder
      let rhsSortOrder = rhs.element.sortOrder

      guard lhsSortOrder == rhsSortOrder else {
        // Sort by sort order first
        return lhsSortOrder < rhsSortOrder
      }

      // If the sort order is the same, sort by index
      return lhs.offset < rhs.offset
    }

    for (index, slot) in sortedSlots {
      switch slot {
      case .active(let simulator, false) where exclusive != true:
        // We have an active non-exclusive simulator, so reuse it
        return try await (
          reuseSimulator(simulator, config: config, exclusive: exclusive, slotIndex: index),
          slotIndex: index
        )

      case .pendingDeletion(let simulator, let task):
        // We have a pending deletion, so we can reuse it
        Logger.simulatorManager.info(
          """
          ♻️ Turning a pending deletion of simulator \(simulator, privacy: .public) into an \
          active \(exclusive ? "exclusive" : "non-exclusive", privacy: .public) simulator
          """
        )

        simulatorSlots[config]![index] = .active(simulator, exclusive: exclusive)

        task.cancel()

        return try await (
          reuseSimulator(simulator, config: config, exclusive: exclusive, slotIndex: index),
          slotIndex: index
        )

      case .empty:
        let task = createCloneTask(config: config, exclusive: exclusive, slotIndex: index)
        simulatorSlots[config]![index] = .pendingCreation(task, exclusive: exclusive)
        return try await (task.value, slotIndex: index)

      case .pendingCreation(let task, false) where exclusive == false:
        // We have a non-exclusive simulator pending creation, so reuse it
        let simulator = try await task.value

        // We call `incrementReferenceCount()` instead of `reuseSimulator()` here, because the
        // simulator is freshly created, so we can (hopefully) assume it is in a good state
        incrementReferenceCount(for: simulator)

        return (simulator, slotIndex: index)

      default:
        // Ignore incompatible slots
        break
      }
    }

    // If we got here, we need to add a new slot
    let index = simulatorSlots[config]!.count
    let task = createCloneTask(config: config, exclusive: exclusive, slotIndex: index)
    simulatorSlots[config]!.append(.pendingCreation(task, exclusive: exclusive))
    return try await (task.value, slotIndex: index)
  }

  private func reuseSimulator(
    _ simulator: SimulatorUDID,
    config: SimulatorConfig,
    exclusive: Bool,
    slotIndex: Int
  ) async throws -> SimulatorUDID {
    incrementReferenceCount(for: simulator)

    do {
      // Wait for it to boot. This shouldn't be necessary, but sometimes the simulator will
      // reboot because of a migration. This also guards against a simulator being deleted out
      // from under us, as it will error, and we can then "delete" it and return a new one.
      try await simulatorControl.ensureBooted(
        simulator,
        context: "getSimulator, reused: \(config.cloneDeviceName(index: slotIndex))"
      )

      return simulator
    } catch let error as ProcessError where error.exitCode == 148 {
      // 148 happens for "Invalid device". So it either has already been deleted or it's corrupt
      // in some way. Either way, we will "delete" it and return a new one.
      Logger.simulatorManager.warning(
        """
        ⚠️ Boot of existing simulator \(simulator, privacy: .public) failed; deleting and \
        returning a new simulator: \(error, privacy: .public)
        """
      )

      // If we fail to delete, don't throw an error
      try? await delete(
        simulator,
        config: config,
        slotIndex: slotIndex,
        // We can't clean up slots, since we assign to it below
        cleanUpSlots: false,
        context: "getSimulator, reused: \(config.cloneDeviceName(index: slotIndex))"
      )

      let task = createCloneTask(config: config, exclusive: exclusive, slotIndex: slotIndex)
      simulatorSlots[config]![slotIndex] = .pendingCreation(task, exclusive: exclusive)
      return try await task.value
    } catch {
      // We don't know what state the simulator is in, so don't leave it to be handed out again.
      // Without this, the reference taken above is never released, and the slot stays `.active`
      // for the life of the daemon, first in line for every later lease.
      await abandonReuse(of: simulator, config: config, slotIndex: slotIndex)
      throw error
    }
  }

  /// Drops the reference a failed `reuseSimulator` took, deleting the simulator if no other lease
  /// still holds it.
  private func abandonReuse(
    of simulator: SimulatorUDID,
    config: SimulatorConfig,
    slotIndex: Int
  ) async {
    guard let count = referenceCount[simulator] else {
      return
    }

    guard count == 1 else {
      referenceCount[simulator] = count - 1
      return
    }

    Logger.simulatorManager.warning(
      "⚠️ Deleting simulator \(simulator, privacy: .public) after a failed reuse"
    )

    // If we fail to delete, don't throw an error; the caller reports the original failure
    try? await delete(
      simulator,
      config: config,
      slotIndex: slotIndex,
      cleanUpSlots: true,
      context: "abandonReuse: \(config.cloneDeviceName(index: slotIndex))"
    )
  }

  private func createCloneTask(
    config: SimulatorConfig,
    exclusive: Bool,
    slotIndex: Int
  ) -> Task<SimulatorUDID, Error> {
    return Task {
      do {
        let simulator = try await simulatorControl.clone(
          getBase(for: config),
          name: config.cloneDeviceName(index: slotIndex),
          deviceType: config.deviceType,
          runtimeIdentifier: config.runtimeIdentifier(),
          postBoot: postBoot
        )

        simulatorSlots[config]![slotIndex] = .active(simulator, exclusive: exclusive)

        // We want to increment the reference count as soon as we get back from `await`, to ensure
        // that when we suspend and potentially decrement the reference count, we don't delete the
        // simulator before we have a chance to use it. Also, since we created the simulator, we
        // should be responsible for incrementing the reference count. Any functions that reuse
        // this task need to increment the reference count as well.
        incrementReferenceCount(for: simulator)

        return simulator
      } catch {
        // If we fail to create the clone, we need to empty the slot, instead
        // of leaving it in a pending state
        simulatorSlots[config]![slotIndex] = .empty

        throw error
      }
    }
  }

  private func registerReleaseOnExit(for leaser: PID) {
    let processSource =
      DispatchSource.makeProcessSource(identifier: leaser, eventMask: .exit, queue: .main)

    var handledExit = false
    let onExitHandler: () -> Void = { [weak self] in
      // Avoid double handling of exit in case the process exits between
      // `processSource.resume()` and the check with `kill`
      guard !handledExit else { return }
      handledExit = true

      Task {
        guard let self else { return }

        Logger.simulatorManager.debug("👋 PID \(leaser, privacy: .public) exited")

        try await self.release(for: leaser)
      }
    }

    processSource.setEventHandler { onExitHandler() }
    processSource.resume()

    // Check to see if the process is already dead and cancel the source if it is, which will
    // trigger `setCancelHandler`, which releases the simulator
    guard processIsRunning(leaser) else {
      processSource.cancel()
      onExitHandler()
      return
    }

    leaserExitListeners[leaser] = processSource
  }

  private func removeReleaseOnExit(for leaser: PID) {
    guard let leaserExitListener = leaserExitListeners[leaser] else { return }
    leaserExitListeners.removeValue(forKey: leaser)
    leaserExitListener.cancel()
  }

  private func pendingDeletion(
    _ simulator: SimulatorUDID,
    config: SimulatorConfig,
    slotIndex: Int
  ) async {
    guard deleteIdleAfter > 0 || deleteRecentlyUsedIdleAfter > 0 else {
      // If we fail to delete, don't throw an error
      try? await delete(
        simulator,
        config: config,
        slotIndex: slotIndex,
        cleanUpSlots: true,
        context: "pendingDeletion immediate"
      )
      return
    }

    let task = Task {
      Logger.simulatorManager.info(
        """
        💤 Scheduling delete of simulator \(simulator, privacy: .public) in \
        \(self.deleteIdleAfter, privacy: .public) to \
        \(self.deleteRecentlyUsedIdleAfter, privacy: .public) seconds
        """
      )

      let now = Date()
      let shortDeadline = now.addingTimeInterval(TimeInterval(deleteIdleAfter))
      let recentlyUsedDeadline = now.addingTimeInterval(TimeInterval(deleteRecentlyUsedIdleAfter))

      while true {
        let remainingTime: TimeInterval
        if recentlyLeased.contains(config) {
          remainingTime = recentlyUsedDeadline.timeIntervalSinceNow
        } else {
          remainingTime = shortDeadline.timeIntervalSinceNow
        }

        if remainingTime <= 0 {
          break
        }

        // Sleep for up-to 1 second before next check
        try await Task.sleep(for: .seconds(min(remainingTime, 1)))
      }

      guard case .pendingDeletion(let slotSimulator, _) = simulatorSlots[config]![slotIndex],
            simulator == slotSimulator else {
        // Simulator was reused, no need to delete
        return
      }

      // If we fail to delete, don't throw an error
      try? await delete(
        simulator,
        config: config,
        slotIndex: slotIndex,
        cleanUpSlots: true,
        context: "pendingDeletion delayed"
      )
    }

    simulatorSlots[config]![slotIndex] = .pendingDeletion(simulator, task)
    persistState()
  }

  private func delete(
    _ simulator: SimulatorUDID,
    config: SimulatorConfig,
    slotIndex: Int,
    cleanUpSlots: Bool,
    context: @escaping @autoclosure () -> String?
  ) async throws {
    let name = config.cloneDeviceName(index: slotIndex)

    Logger.simulatorManager.info(
      "🗑️ Deleting simulator \(simulator, privacy: .public) (\(name, privacy: .public))"
    )

    simulatorSlots[config]![slotIndex] = .deleting(simulator)
    persistState()

    referenceCount.removeValue(forKey: simulator)

    defer {
      // Even if we fail to delete, we need to set the slot to empty
      simulatorSlots[config]![slotIndex] = .empty

      if cleanUpSlots {
        // Shorten up the array by removing any empty slots at the end
        while case .empty = simulatorSlots[config]!.last {
          simulatorSlots[config]!.removeLast()
        }
      }

      persistState()
    }

    try await simulatorControl.delete(simulator, name: name, context: context())

    Logger.simulatorManager.info(
      "🗑️ Deleted simulator \(simulator, privacy: .public) (\(name, privacy: .public)"
    )
  }
}
