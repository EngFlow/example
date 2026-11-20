import Foundation
import NIO
import NIOExtras
import NIOHTTP1
import NIOPosix
import os.log

extension Logger {
  static let httpServer = simulatorManager(category: "server")
}

final class HTTPServer {
  private let simulatorRequestHandler: SimulatorRequestHandler

  private let version: String

  private var serverShutdownHandler: (() -> Void)?

  init(simulatorRequestHandler: SimulatorRequestHandler, version: String) {
    self.simulatorRequestHandler = simulatorRequestHandler
    self.version = version
  }

  func run(pidPath: String, unixSocketPath: String) async throws {
    let socketURL = URL(fileURLWithPath: unixSocketPath)
    let pidURL = URL(fileURLWithPath: pidPath)

    // Remove existing files if they exist
    try? FileManager.default.removeItem(at: socketURL)
    try? FileManager.default.removeItem(at: pidURL)

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    do {
      // This nested block is necessary to ensure that all the destructors for objects defined
      // inside are called before the final call to `eventLoopGroup.syncShutdownGracefully()`. A
      // possible side effect of not doing this is a run-time error "Cannot schedule tasks on an
      // EventLoop that has already shut down".
      let quiesce = ServerQuiescingHelper(group: eventLoopGroup)
      let fullyShutdownPromise: EventLoopPromise<Void> = eventLoopGroup.next().makePromise()
      serverShutdownHandler = {
        Logger.httpServer.info("⚠️ Shutting down server")
        quiesce.initiateShutdown(promise: fullyShutdownPromise)
      }

      do {
        // The socket lives in /tmp, and anyone who can connect to it can shut the daemon down or
        // release another test's simulator. So create it owner-only: under the default umask it
        // would be connectable by every user on the machine. Set the umask around `bind` rather
        // than `chmod`ing afterwards, which would leave a window where the socket is open to all.
        let serverChannel = try await withUmask(0o077) {
          try await ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelInitializer { channel in
              return channel.eventLoop.makeCompletedFuture {
                try channel.pipeline.syncOperations.addHandler(
                  quiesce.makeServerChannelHandler(channel: channel)
                )
              }
            }
            .bind(unixDomainSocketPath: unixSocketPath, childChannelInitializer: { childChannel in
              return childChannel.eventLoop.makeCompletedFuture {
                try childChannel.pipeline.syncOperations.addHandlers([
                  HTTPResponseEncoder(),
                  ByteToMessageHandler(HTTPRequestDecoder()),
                  AccumulatedHTTPHandler(),
                  SimulatorManagerHTTPHandler(),
                ])

                return try NIOAsyncChannel<SimulatorManagerRequest, SimulatorManagerResponse>(
                  wrappingChannelSynchronously: childChannel,
                  configuration: .init()
                )
              }
            })
        }

        // start.sh treats the pid file as the signal that the server is ready, so only write it
        // once the socket is bound. Writing it earlier let start.sh find a live pid with no
        // socket behind it yet, fail to read the version, and start a second daemon.
        try String(ProcessInfo.processInfo.processIdentifier).write(
          to: pidURL,
          atomically: true,
          encoding: .utf8
        )

        Logger.httpServer.info("🔌 Server running on UDS at \(unixSocketPath, privacy: .public)")

        try await withThrowingDiscardingTaskGroup { group in
          try await serverChannel.executeThenClose { inbound in
            for try await connectionChannel in inbound {
              group.addTask {
                do {
                  try await self.handleConnection(
                    channel: connectionChannel
                  )
                } catch {
                  // We don't throw here, as it locks up the whole server
                  Logger.httpServer.error(
                    """
                    ❌ Caught connection error: \(error, privacy: .public)
                    """
                  )
                }
              }
            }
          }
        }
      } catch {
        Logger.httpServer.error("❌ Caught top-level error: \(error, privacy: .public)")
        try await eventLoopGroup.shutdownGracefully()
        throw error
      }

      try await fullyShutdownPromise.futureResult.get()
    }

    try await eventLoopGroup.shutdownGracefully()
    Logger.httpServer.info("✅ Server shut down")

    // Cleanup files
    try? FileManager.default.removeItem(at: socketURL)
    try? FileManager.default.removeItem(at: pidURL)
  }

  private func handleConnection(
    channel: NIOAsyncChannel<SimulatorManagerRequest, SimulatorManagerResponse>
  ) async throws {
    try await channel.executeThenClose { inbound, outbound in
      for try await request in inbound {
        try await outbound.write(handleRequest(request))
      }
    }
  }

  private func handleRequest(
    _ request: SimulatorManagerRequest
  ) async -> SimulatorManagerResponse {
    switch request.path {
    case "simulator":
      do {
        return try await simulatorRequestHandler.handleRequest(
          method: request.method,
          pathComponents: request.pathComponents,
          queryParameters: request.queryParameters
        )
      } catch {
        Logger.httpServer.error(
          "❌ simulatorRequestHandler.handleRequest error: \(error, privacy: .public)"
        )

        return .init(
          status: .internalServerError,
          message: "Internal server error: \(error)"
        )
      }

    case "version":
      guard request.method == .GET else { return methodNotAllowed(request) }
      return .init(
        status: .ok,
        message: version
      )

    case "leases":
      guard request.method == .GET else { return methodNotAllowed(request) }
      let count = await simulatorRequestHandler.liveLeaseCount()
      return .init(status: .ok, message: String(count))

    case "shutdown":
      // POST only, so that nothing which merely fetches URLs can shut the daemon down.
      guard request.method == .POST else { return methodNotAllowed(request) }
      // Shutting down with leases outstanding is safe: they are mirrored to disk,
      // and the replacement daemon adopts the ones whose process is still running.
      Logger.httpServer.info("⚠️ Shutdown request received")
      serverShutdownHandler?()
      return .init(status: .ok, message: "Server shutting down")

    default:
      return .init(status: .notFound, message: "Unknown path: \(request.path)")
    }
  }

  /// Runs `body` with the process umask set to `mask`. The umask is process-wide, so anything
  /// else creating a file meanwhile gets it too; keep `body` short.
  private func withUmask<T>(_ mask: mode_t, _ body: () async throws -> T) async rethrows -> T {
    let previous = umask(mask)
    defer { umask(previous) }
    return try await body()
  }

  private func methodNotAllowed(_ request: SimulatorManagerRequest) -> SimulatorManagerResponse {
    return .init(
      status: .methodNotAllowed,
      message: "Unsupported HTTP method for /\(request.path): \(request.method)"
    )
  }
}
