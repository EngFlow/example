import NIO
import NIOHTTP1
import os.log

extension Logger {
  static let accumulatedHTTP = simulatorManager(category: "accumulated_http")
}

struct FullHTTPRequest {
  let head: HTTPRequestHead
  var body: ByteBuffer
}

struct FullHTTPResponse {
  let head: HTTPResponseHead
  var body: ByteBuffer
}

final class AccumulatedHTTPHandler: ChannelInboundHandler, ChannelOutboundHandler {
  typealias InboundIn = HTTPServerRequestPart
  typealias InboundOut = FullHTTPRequest

  typealias OutboundIn = FullHTTPResponse
  typealias OutboundOut = HTTPServerResponsePart

  private var requestHead: HTTPRequestHead?
  private var bodyBuffer: ByteBuffer?

  /// Requests passed on whose response hasn't been written yet.
  private var requestsAwaitingResponse = 0
  /// Set once the server starts shutting down, after which the connection closes as soon as it
  /// has nothing left to answer.
  private var quiescing = false

  /// Whether the connection is between requests, with nothing received that it still has to
  /// answer.
  private var isIdle: Bool {
    return requestHead == nil && requestsAwaitingResponse == 0
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let part = self.unwrapInboundIn(data)

    switch part {
    case .head(let head):
      self.requestHead = head
      self.bodyBuffer = context.channel.allocator.buffer(capacity: 0)

    case .body(var chunk):
      self.bodyBuffer?.writeBuffer(&chunk)

    case .end:
      if let head = requestHead, let body = bodyBuffer {
        Logger.accumulatedHTTP.info(
          """
          ▶️ Received \(head.method.rawValue, privacy: .public) request for \
          \(head.uri, privacy: .public)
          """
        )

        requestsAwaitingResponse += 1
        let fullRequest = FullHTTPRequest(head: head, body: body)
        context.fireChannelRead(self.wrapInboundOut(fullRequest))
      }

      self.requestHead = nil
      self.bodyBuffer = nil
    }
  }

  /// The server's quiescing helper sends this to every open connection on shutdown, and the
  /// shutdown only completes once they have all closed. A connection held open by a keep-alive
  /// client would otherwise never close, until `start.sh` gave up and killed the daemon.
  func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
    guard event is ChannelShouldQuiesceEvent else {
      context.fireUserInboundEventTriggered(event)
      return
    }

    quiescing = true
    if isIdle {
      context.close(promise: nil)
    }
  }

  func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
    let fullResponse = unwrapOutboundIn(data)
    requestsAwaitingResponse = max(requestsAwaitingResponse - 1, 0)

    Logger.accumulatedHTTP.info(
      "◀️ Sending \(fullResponse.head.status, privacy: .public) response"
    )

    let closeAfterwards = quiescing && isIdle
    var head = fullResponse.head
    if closeAfterwards {
      head.headers.replaceOrAdd(name: "Connection", value: "close")
    }

    context.write(wrapOutboundOut(.head(head)), promise: nil)

    if fullResponse.body.readableBytes > 0 {
      context.write(wrapOutboundOut(.body(.byteBuffer(fullResponse.body))), promise: nil)
    }

    guard closeAfterwards else {
      context.write(wrapOutboundOut(.end(nil)), promise: promise)
      return
    }

    let written = context.eventLoop.makePromise(of: Void.self)
    context.write(wrapOutboundOut(.end(nil)), promise: written)
    written.futureResult.whenComplete { [channel = context.channel] _ in
      channel.close(promise: nil)
    }
    written.futureResult.cascade(to: promise)
  }

  func errorCaught(context: ChannelHandlerContext, error: Error) {
    Logger.accumulatedHTTP.error(
      "❌ \(error.localizedDescription, privacy: .public)"
    )
    context.close(promise: nil)
  }
}
