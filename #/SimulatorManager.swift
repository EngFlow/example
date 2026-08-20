import Foundation
import os
import ShellOut

typealias PID = pid_t

extension Logger {
  static let simulatorManager = simulatorManager(category: "manager")
  static let childProcess = simulatorManager(category: "manager.child-process")
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
    // Try to use an active simulator first (should only be one for non-exclusive)
    case .active:
      return 0

    // A pending deletion is already created and booted, so reuse it before waiting
    // on a pending creation or starting a fresh one.
    case .pendingDeletion:
      return 1

    // Use an empty slot before waiting on a pending creation, so a lease doesn't
    // block on someone else's in-flight clone when a fresh slot is free to start.
    case .empty:
      return 2

    case .pendingCreation:
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

  private var startupProcessPaths: [String]
  private var postBoot: String?
  private var childProcessTasks: [Task<Void, Never>] = []
  private var childProcesses: [String: (Process, DispatchSourceRead, DispatchSourceRead)] = [:]

  private var reaperTask: Task<Void, Never>?
  /// Clone UDIDs that looked orphaned on the *previous* sweep. A device must appear
  /// unknown on two consecutive sweeps before the reaper deletes it, so a clone that's
  /// mid-creation (it exists on disk before `createCloneTask` resumes and records it in
  /// `referenceCount`) never gets caught by a single unlucky sweep.
  private var previousOrphanCandidates: Set<SimulatorUDID> = []
  /// How many sweeps in a row the reaper has failed to delete a confirmed orphan.
  /// Reset once a delete succeeds, or once the UDID stops being an orphan at all
  /// (claimed by a new lease, or already cleaned up some other way).
  private var orphanDeleteFailureCounts: [SimulatorUDID: Int] = [:]
  /// After this many consecutive failed deletes, a device is treated as wedged
  /// rather than merely unlucky: normal `simctl shutdown`/`delete` retries have
  /// already been exhausted inside `SimulatorControl.delete()` every sweep, so more
  /// of the same is unlikely to help. Escalate to killing its `launchd_sim` directly.
  private let forceKillAfterFailedReapAttempts = 3

  init(
    simulatorControl: SimulatorControl,
    deleteRecentlyUsedIdleAfter: UInt16,
    deleteIdleAfter: UInt16,
    recentlyUsedCapacity: Int,
    deleteOnPIDExit: Bool,
    startupProcesses: [String] = [],
    postBoot: String? = nil,
    leaseStore: LeaseStore? = nil
  ) {
    self.simulatorControl = simulatorControl
    self.deleteIdleAfter = deleteIdleAfter
    self.deleteRecentlyUsedIdleAfter = deleteRecentlyUsedIdleAfter
    self.deleteOnPIDExit = deleteOnPIDExit
    self.recentlyLeased = LRUSet(capacity: recentlyUsedCapacity)
    self.startupProcessPaths = startupProcesses
    self.postBoot = postBoot
    self.leaseStore = leaseStore

    // Change the working directory to some place stable, since on RBE the runfiles directory can
    // get cleaned up
    FileManager.default.changeCurrentDirectoryPath("/tmp")
  }

  deinit {
    reaperTask?.cancel()

    for task in childProcessTasks {
      task.cancel()
    }

    for (process, outWatcher, errWatcher) in childProcesses.values {
      process.terminate()
      outWatcher.cancel()
      errWatcher.cancel()
    }
  }

  func startChildProcesses() throws {
    for path in startupProcessPaths {
      childProcessTasks.append(createStartChildProcessTask(path: path))
    }
  }

  /// Starts the periodic sweep that deletes clone simulators the manager has lost
  /// track of.
  ///
  /// Every other cleanup path is event-driven: an explicit release, a PID-exit
  /// watcher, an idle timer, or "rediscovered by name on the next lease of the same
  /// config." Each of those can miss a device -- a daemon restart drops a lease
  /// whose device is never leased again (see `restoreLeases`), or a `simctl delete`
  /// call fails and is swallowed (see `delete`) -- and nothing else ever looks for
  /// it again. This sweep is the backstop: it reconciles against what CoreSimulator
  /// actually has running, independent of how a device became untracked.
  ///
  /// `interval <= .zero` disables it, matching how `deleteIdleAfter` of 0 means
  /// "immediately" elsewhere in this file rather than "never."
  func startReaper(interval: Duration) {
    guard interval > .zero else { return }

    reaperTask = Task {
      while !Task.isCancelled {
        try? await Task.sleep(for: interval)
        guard !Task.isCancelled else { break }
        await reapOrphanedSimulators()
      }
    }
  }

  /// One sweep of the orphan reaper: list every clone simulator that exists, and
  /// delete the ones with no entry in `referenceCount`.
  ///
  /// `referenceCount` is the right ground truth to check against, not `leases` or
  /// `simulatorSlots`: a device gets an entry in it the instant it's claimed (before
  /// any `await`, per the invariant on `getSimulator`), and the entry is removed
  /// only in `delete()` -- including while the device sits in the idle-timer grace
  /// period, where the count is `0` but the key stays. So "no entry" reliably means
  /// "the manager has no idea this exists," not merely "nothing is leasing it right
  /// now."
  ///
  /// Bypasses `delete()` deliberately: that function updates a slot in
  /// `simulatorSlots`, but an orphan by definition has no slot pointing at it, so
  /// there is nothing there to update. This calls `simulatorControl` directly, the
  /// same lower-level operation `delete()` itself wraps.
  private func reapOrphanedSimulators() async {
    let known = Set(referenceCount.keys)

    let managedClones: [SimCtlDevice]
    do {
      managedClones = try await simulatorControl.listManagedClones()
    } catch {
      Logger.simulatorManager.error(
        "❌ Orphan reaper failed to list simulators, skipping this sweep: \(error, privacy: .public)"
      )
      return
    }

    let currentOrphanCandidates = Set(managedClones.map(\.udid)).subtracting(known)
    let confirmedOrphans = currentOrphanCandidates.intersection(previousOrphanCandidates)
    previousOrphanCandidates = currentOrphanCandidates

    // Forget the failure count for anything that isn't a confirmed orphan any more
    // (claimed by a new lease, or already cleaned up), so a UDID that's reused later
    // starts with a clean slate rather than inheriting an old device's history.
    orphanDeleteFailureCounts = orphanDeleteFailureCounts.filter { confirmedOrphans.contains($0.key) }

    guard !confirmedOrphans.isEmpty else { return }

    for device in managedClones where confirmedOrphans.contains(device.udid) {
      await reapOrphan(device)
    }
  }

  /// Deletes one confirmed-orphaned device, escalating to a direct kill of its
  /// `launchd_sim` if it has already failed to delete
  /// `forceKillAfterFailedReapAttempts` sweeps in a row.
  ///
  /// `SimulatorControl.delete()` already shuts the device down and retries a few
  /// times internally before throwing, so a failure reaching here means those
  /// retries were exhausted -- consistent with a genuinely wedged device (the same
  /// profile as the multi-day-old `launchd_sim` processes that motivated this), not
  /// a one-off transient error. Retrying the same call every 5-minute sweep forever
  /// would just fail the same way forever, silently; escalating is what makes this a
  /// backstop instead of another silent no-op.
  private func reapOrphan(_ device: SimCtlDevice) async {
    Logger.simulatorManager.warning(
      """
      🧹 Reaping orphaned simulator \(device.udid, privacy: .public) \
      (\(device.name, privacy: .public)); the manager has no lease or reference to it
      """
    )

    do {
      try await simulatorControl.delete(device.udid, name: device.name, context: "orphan reaper")
      orphanDeleteFailureCounts.removeValue(forKey: device.udid)
      return
    } catch {
      let failures = (orphanDeleteFailureCounts[device.udid] ?? 0) + 1
      orphanDeleteFailureCounts[device.udid] = failures

      Logger.simulatorManager.error(
        """
        ❌ Orphan reaper failed to delete \(device.udid, privacy: .public) \
        (\(device.name, privacy: .public)), attempt \(failures, privacy: .public): \
        \(error, privacy: .public)
        """
      )

      guard failures >= forceKillAfterFailedReapAttempts else { return }

      Logger.simulatorManager.error(
        """
        🔨 \(device.udid, privacy: .public) (\(device.name, privacy: .public)) has failed to \
        delete \(failures, privacy: .public) sweeps in a row; force-killing its launchd_sim
        """
      )

      await simulatorControl.forceKillLaunchdSim(for: device.udid)

      do {
        try await simulatorControl.delete(
          device.udid,
          name: device.name,
          context: "orphan reaper, post force-kill"
        )
        orphanDeleteFailureCounts.removeValue(forKey: device.udid)
      } catch {
        Logger.simulatorManager.error(
          """
          ❌ \(device.udid, privacy: .public) (\(device.name, privacy: .public)) still failed to \
          delete after force-killing launchd_sim: \(error, privacy: .public). Needs manual cleanup.
          """
        )
      }
    }
  }

  /// Adopts the leases a previous daemon left behind.
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
  /// Leases whose process is gone are dropped rather than adopted. The device they
  /// held is left alone: `createBase`/`clone` find existing devices by name, so it
  /// gets picked up and reference counted by the next lease of that config.
  func restoreLeases() {
    guard let leaseStore else { return }

    let persisted = leaseStore.load()
    guard !persisted.isEmpty else { return }

    var adopted = 0
    var dropped = 0

    for lease in persisted {
      guard leaserSurvived(lease) else {
        dropped += 1
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

      incrementReferenceCount(for: lease.udid)

      if deleteOnPIDExit {
        registerReleaseOnExit(for: lease.pid)
      }

      adopted += 1
    }

    Logger.simulatorManager.info(
      """
      ♻️ Restored \(adopted, privacy: .public) lease(s) from a previous simulator \
      manager; dropped \(dropped, privacy: .public) whose process had exited
      """
    )

    // The dropped entries are gone for good, so rewrite the file rather than let a
    // later crash re-adopt them.
    persistLeases()
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

  /// Mirrors the current leases to disk.
  ///
  /// Called on every change rather than at shutdown, because the daemon is not
  /// always shut down politely: `start.sh` escalates to `kill -9`, which runs no
  /// cleanup. Each lease costs a small JSON write, against provisioning a
  /// simulator that takes seconds.
  private func persistLeases() {
    guard let leaseStore else { return }

    leaseStore.save(
      leases.map { pid, lease in
        .init(
          pid: pid,
          leaserStartTime: lease.leaserStartTime,
          udid: lease.udid,
          config: lease.config,
          exclusive: lease.exclusive,
          slotIndex: lease.slotIndex
        )
      }
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

    _ = recentlyLeased.insert(config)

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
    persistLeases()

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
    persistLeases()

    removeReleaseOnExit(for: leaser)

    await simulatorControl.cleanTempFiles(in: lease.udid)

    try await decrementReferenceCount(
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
  ) async throws {
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
    } catch let error as ProcessError {
      // 148 happens for "Invalid device". So it either has already been deleted or it's corrupt
      // in some way. Either way, we will "delete" it and return a new one.
      guard error.exitCode == 148 else {
        throw error
      }

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
    }
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

    // Avoid double handling of exit in case the process exits between
    // `processSource.resume()` and the check with `kill` below. The event handler runs
    // on `.main`, while the liveness check below runs on whatever thread calls this
    // method, so the flag guarding against a double call must itself be synchronized.
    let handledExitLock = NSLock()
    var handledExit = false
    let onExitHandler: () -> Void = { [weak self] in
      handledExitLock.lock()
      let alreadyHandled = handledExit
      handledExit = true
      handledExitLock.unlock()
      guard !alreadyHandled else { return }

      Task {
        guard let self else { return }

        Logger.simulatorManager.debug("👋 PID \(leaser, privacy: .public) exited")

        try await self.release(for: leaser)
      }
    }

    processSource.setEventHandler { onExitHandler() }
    processSource.resume()

    // Check to see if the process is already dead. There is no `setCancelHandler`, so
    // handle the exit directly here rather than relying on cancellation to do it.
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
    }

    try await simulatorControl.delete(simulator, name: name, context: context())

    Logger.simulatorManager.info(
      "🗑️ Deleted simulator \(simulator, privacy: .public) (\(name, privacy: .public)"
    )
  }

  // MARK: Child Process Management

  private nonisolated func createStartChildProcessTask(path: String) -> Task<Void, Never> {
    return Task.detached { [weak self] in
      let process: Process
      do {
        guard let self else { return }
        process = try await self.createProcess(path: path)
        // `self` drops out of scope here, so `SimulatorManager` can deinit
      } catch {
        Logger.simulatorManager.info(
          """
          ❌ Failed to create child process at "\(path, privacy: .public)": \
          \(error, privacy: .public)
          """
        )
        return
      }

      await withCheckedContinuation { cont in
        process.terminationHandler = { proc in
          let exitCode = proc.terminationStatus
          Logger.simulatorManager.warning(
            """
            ⚠️ "\(path, privacy: .public)" exited with code: \(exitCode, privacy: .public)
            """
          )
          cont.resume()
        }

        do {
          Logger.simulatorManager.info(
            #"🧒 Starting "\#(path, privacy: .public)""#
          )
          try process.run()
        } catch {
          Logger.simulatorManager.info(
            """
            ❌ Failed to start "\(path, privacy: .public)": \
            \(error, privacy: .public)
            """
          )
          cont.resume()
        }
      }
    }
  }

  private func createProcess(path: String) throws -> Process {
    let process = Process()

    process.executableURL = URL(fileURLWithPath: path)

    let outPTY = try PTY()
    process.standardOutput = FileHandle(fileDescriptor: outPTY.child, closeOnDealloc: true)
    let outQueue = DispatchQueue(label: "com.example.simulator_manager.child_process.out")
    let outWatcher = watch(fd: outPTY.parent, queue: outQueue) { line in
      Logger.childProcess.info("[\(path, privacy: .public)] \(line, privacy: .public)")
    }

    let errPTY = try PTY()
    process.standardError = FileHandle(fileDescriptor: errPTY.child, closeOnDealloc: true)
    let errQueue = DispatchQueue(label: "com.example.simulator_manager.child_process.err")
    let errWatcher = watch(fd: errPTY.parent, queue: errQueue) { line in
      Logger.childProcess.error("[\(path, privacy: .public)] \(line, privacy: .public)")
    }

    childProcesses[path] = (process, outWatcher, errWatcher)

    return process
  }
}

/// Installs a DispatchSourceRead on `fd`.
private func watch(
  fd: Int32,
  queue: DispatchQueue,
  onLine: @escaping (String) -> Void
) -> DispatchSourceRead {
  let src = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
  var buffer = Data()

  src.setEventHandler {
    var tmp = [UInt8](repeating: 0, count: 4096)
    let n = read(fd, &tmp, tmp.count)
    guard n > 0 else {
      src.cancel()
      close(fd)
      return
    }

    buffer.append(contentsOf: tmp[0..<n])

    // Split on newline; last segment may be an incomplete tail
    let segments = buffer.split(
      separator: UInt8(ascii: "\n"),
      omittingEmptySubsequences: false
    )

    // Emit every complete line (all but the last segment)
    for lineData in segments.dropLast() {
      if let line = String(data: lineData, encoding: .utf8) {
        onLine(line)
      }
    }

    // Keep the last segment (possibly empty or partial) for next time
    buffer = Data(segments.last ?? Data())
  }

  src.resume()

  return src
}
