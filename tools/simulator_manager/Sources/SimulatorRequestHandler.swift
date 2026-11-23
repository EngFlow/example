import NIOHTTP1

final class SimulatorRequestHandler {
  private let simulatorManager: SimulatorManager

  init(simulatorManager: SimulatorManager) {
    self.simulatorManager = simulatorManager
  }

  /// The number of leases still held by running processes, for diagnostics.
  func liveLeaseCount() async -> Int {
    return await simulatorManager.liveLeaseCount()
  }

  func handleRequest(
    method: HTTPMethod,
    pathComponents: [String],
    queryParameters: [String: String]
  ) async throws -> SimulatorManagerResponse {
    switch method {
    case .POST:
      guard pathComponents.count >= 1 else {
        return .init(
          status: .badRequest,
          message: "Must specify <leaser PID>"
        )
      }

      guard let leaser = PID(pathComponents[0]) else {
        return .init(status: .badRequest, message: "Leaser PID must be an integer")
      }
      guard let exclusiveString = queryParameters["exclusive"] else {
        return .init(status: .badRequest, message: "Must specify 'exclusive' query parameter")
      }
      // Anything else is rejected rather than read as false: `exclusive=true` used to silently
      // produce a shared lease.
      let exclusive: Bool
      switch exclusiveString {
      case "1", "true":
        exclusive = true
      case "0", "false":
        exclusive = false
      default:
        return .init(
          status: .badRequest,
          message: "'exclusive' must be 1, 0, true, or false, not '\(exclusiveString)'"
        )
      }
      guard let deviceType = queryParameters["deviceType"] else {
        return .init(status: .badRequest, message: "Must specify 'deviceType' query parameter")
      }
      guard let os = queryParameters["os"] else {
        return .init(status: .badRequest, message: "Must specify 'os' query parameter")
      }
      guard let version = queryParameters["version"] else {
        return .init(status: .badRequest, message: "Must specify 'version' query parameter")
      }

      let config = SimulatorConfig(
        deviceType: deviceType,
        os: os,
        version: version
      )

      do {
        return try await .init(
          status: .created,
          message: simulatorManager
            .lease(to: leaser, exclusive: exclusive, config: config)
        )
      } catch SimulatorManagerError.alreadyLeased(let udid) {
        // A conflict with the PID's existing lease, not a malformed request.
        return .init(
          status: .conflict,
          // FIXME: Get this from the error itself
          message: "PID \(leaser) has already leased another simulator: \(udid)"
        )
      } catch SimulatorManagerError.leaseInProgress {
        return .init(
          status: .conflict,
          message: "PID \(leaser) already has a simulator lease being provisioned"
        )
      } catch SimulatorManagerError.leaserExited {
        // Nobody is left to read this response, but answering rather than throwing
        // keeps it out of the server's error path.
        return .init(
          status: .gone,
          message: "PID \(leaser) exited before its simulator was provisioned"
        )
      }

    case .DELETE:
      guard pathComponents.count >= 1 else {
        return .init(
          status: .badRequest,
          message: "Must specify <leaser PID>"
        )
      }

      guard let leaser = PID(pathComponents[0]) else {
        return .init(status: .badRequest, message: "Leaser PID must be an integer")
      }

      do {
        try await simulatorManager.release(for: leaser)

        return .init(
          status: .ok,
          message: "Success"
        )
      } catch SimulatorManagerError.noLease {
        return .init(
          status: .notFound,
          // FIXME: Get this message from the error itself
          message: "PID \(leaser) doesn't have a simulator leased"
        )
      }

    default:
      return .init(status: .methodNotAllowed, message: "Unsupported HTTP method: \(method)")
    }
  }
}
