//
//  NIOWebUploaderHandler.swift
//  Passepartout
//
//  Created by Davide De Rosa on 6/6/25.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonLibrary
import Foundation
import NIO
import NIOHTTP1

final class NIOWebUploaderHandler {
    typealias InboundIn = HTTPServerRequestPart

    typealias OutboundOut = HTTPServerResponsePart

    private static let html: String = {
        do {
            guard let path = Bundle.module.path(forResource: "web_uploader", ofType: "html") else {
                throw AppError.notFound
            }
            let contents = try String(contentsOfFile: path)
            let template = HTMLTemplate(html: contents)
            return template.withLocalizedKeys(in: .module)
        } catch {
            fatalError("Unable to load web uploader HTML template")
        }
    }()

    private let passcode: String?

    private let onReceive: (String, String) -> Void

    private var requestHead: HTTPRequestHead?

    private var bodyBuffer: ByteBuffer?

    init(passcode: String?, onReceive: @escaping (String, String) -> Void) {
        self.passcode = passcode
        self.onReceive = onReceive
    }
}

// MARK: - ChannelInboundHandler

extension NIOWebUploaderHandler: ChannelInboundHandler {
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

private extension NIOWebUploaderHandler {
    func handleGET(_ context: ChannelHandlerContext, uri: String) -> Bool {
        guard uri == "/" else {
            return false
        }
        sendHTMLResponse(context, html: Self.html)
        return true
    }

    func handlePOST(_ context: ChannelHandlerContext, uri: String) -> Bool {
        guard uri == "/upload" else {
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

extension NIOWebUploaderHandler {
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
