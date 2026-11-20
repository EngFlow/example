import Foundation
import os

extension Logger {
  static let leaseStore = simulatorManager(category: "manager.lease-store")
}

/// A lease, in the form it takes on disk.
///
/// Holds everything needed to rebuild the daemon's in-memory bookkeeping for one
/// lease: which device, under which configuration, in which slot, and whether it
/// was owned exclusively. Nothing here has to be re-derived by asking `simctl`.
struct PersistedLease: Codable, Equatable {
  let pid: PID
  /// The leaser's start time, used to tell "PID 500 is still running" apart from
  /// "PID 500 exited and something unrelated is now PID 500".
  ///
  /// Optional so a record written by a build that could not read the start time
  /// still loads; such a record is restored on liveness alone.
  let leaserStartTime: UInt64?
  let udid: SimulatorUDID
  let config: SimulatorConfig
  let exclusive: Bool
  let slotIndex: Int
}

/// Where the daemon keeps its leases so a successor can pick them up.
protocol LeaseStore: Sendable {
  /// Replaces the stored set with `leases`. Failures are logged, not thrown:
  /// losing persistence degrades a restart, but failing the lease that triggered
  /// the write would break a test that is otherwise fine.
  func save(_ leases: [PersistedLease])

  /// The stored set, or empty if there is nothing readable to restore.
  func load() -> [PersistedLease]
}

/// A `LeaseStore` backed by a JSON file.
///
/// Written atomically, so a reader never sees a half-written set and a crash
/// mid-write leaves the previous contents intact. Combined with writing on every
/// change, this means the file is always current -- there is no flush-on-shutdown
/// step for a `kill -9` to skip.
struct FileLeaseStore: LeaseStore {
  let path: String

  func save(_ leases: [PersistedLease]) {
    let url = URL(fileURLWithPath: path)
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(leases)

      // `.atomic` writes an auxiliary file alongside the destination and renames
      // it over the top, which is the whole reason this is durable. Doing that by
      // hand would only duplicate it, and would leave a stray file of our own
      // naming behind if we crashed between the write and the rename.
      try data.write(to: url, options: .atomic)
    } catch {
      Logger.leaseStore.error(
        """
        ❌ Failed to persist \(leases.count, privacy: .public) lease(s) to \
        \(path, privacy: .public): \(error, privacy: .public)
        """
      )
    }
  }

  func load() -> [PersistedLease] {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else {
      return []
    }

    do {
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode([PersistedLease].self, from: data)
    } catch {
      // A corrupt or stale-format file must not stop the daemon from starting.
      // The cost of ignoring it is the old behavior: leases predating the restart
      // are unknown, and their releases report no lease.
      Logger.leaseStore.error(
        """
        ❌ Failed to read leases from \(path, privacy: .public); continuing with \
        none: \(error, privacy: .public)
        """
      )
      return []
    }
  }
}

/// When `pid` started, in microseconds since the epoch, or nil if it cannot be
/// determined (typically because the process is gone).
///
/// A PID alone does not identify a process across a daemon restart: PIDs are
/// recycled, so a lease for a dead PID could otherwise be restored onto whatever
/// unrelated process now holds that number, tying up a device until it exits.
/// Start time distinguishes them -- the kernel assigns it at fork, so a recycled
/// PID has a different one.
func processStartTime(_ pid: PID) -> UInt64? {
  var info = kinfo_proc()
  var size = MemoryLayout<kinfo_proc>.stride
  var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]

  guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0, size > 0 else {
    return nil
  }

  let startTime = info.kp_proc.p_starttime
  return UInt64(startTime.tv_sec) * 1_000_000 + UInt64(startTime.tv_usec)
}
