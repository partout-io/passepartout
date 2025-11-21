// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(tvOS)

import Foundation
import NIO
import NIOHTTP1

final class NIOWebReceiverHandler: @unchecked Sendable {
    typealias InboundIn = HTTPServerRequestPart

    typealias OutboundOut = HTTPServerResponsePart

    private let html: String

    private let passcode: String?

    private let onReceive: @Sendable (String, String) -> Void

    private var requestHead: HTTPRequestHead?

    private var bodyBuffer: ByteBuffer?

    init(html: String, passcode: String?, onReceive: @escaping @Sendable (String, String) -> Void) {
        self.html = html
        self.passcode = passcode
        self.onReceive = onReceive
    }
}

// MARK: - ChannelInboundHandler

extension NIOWebReceiverHandler: ChannelInboundHandler {
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = unwrapInboundIn(data)
        switch reqPart {
        case .head(let head):
            requestHead = head
            bodyBuffer = context.channel.allocator.buffer(capacity: 0)
        case .body(var chunk):
            bodyBuffer?.writeBuffer(&chunk)
        case .end:
            guard let requestHead else {
                return
            }
            var isHandled = false
            switch requestHead.method {
            case .GET:
                isHandled = handleGET(context, uri: requestHead.uri)
            case .POST:
                isHandled = handlePOST(context, uri: requestHead.uri)
            default:
                break
            }
            if !isHandled {
                sendTextResponse(context, with: .notFound)
            }
            self.requestHead = nil
            bodyBuffer = nil
        }
    }
}

// MARK: - Routes

private extension NIOWebReceiverHandler {
    func handleGET(_ context: ChannelHandlerContext, uri: String) -> Bool {
        guard uri == "/" else {
            return false
        }
        sendHTMLResponse(context, html: html)
        return true
    }

    func handlePOST(_ context: ChannelHandlerContext, uri: String) -> Bool {
        guard uri == "/" else {
            return false
        }
        guard let buffer = bodyBuffer,
              let body = buffer.getString(at: 0, length: buffer.readableBytes),
              let form = MultipartForm(body: body) else {
            sendTextResponse(context, with: .badRequest)
            return true
        }
        if let passcode {
            guard let formPasscode = form.fields["passcode"]?.value,
                  formPasscode.uppercased() == passcode.uppercased() else {
                sendTextResponse(context, with: .forbidden)
                return true
            }
        }
        guard let file = form.fields["file"], let filename = file.filename else {
            sendTextResponse(context, with: .badRequest)
            return true
        }
        sendTextResponse(context, with: .ok)
        onReceive(filename, file.value)
        return true
    }
}

// MARK: - Helpers

extension NIOWebReceiverHandler {
    func sendTextResponse(
        _ context: ChannelHandlerContext,
        with status: HTTPResponseStatus,
        text: String = ""
    ) {
        var response = HTTPResponseHead(version: .http1_1, status: status)
        response.headers.add(name: "Content-Type", value: "text/plain")
        let bufferOut = context.channel.allocator.buffer(string: text)
        context.write(wrapOutboundOut(.head(response)), promise: nil)
        context.write(wrapOutboundOut(.body(.byteBuffer(bufferOut))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }

    func sendHTMLResponse(
        _ context: ChannelHandlerContext,
        html: String
    ) {
        var response = HTTPResponseHead(version: .http1_1, status: .ok)
        response.headers.add(name: "Content-Type", value: "text/html")
        response.headers.add(name: "Content-Length", value: "\(html.utf8.count)")
        let buffer = context.channel.allocator.buffer(string: html)
        context.write(wrapOutboundOut(.head(response)), promise: nil)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }
}

#endif
