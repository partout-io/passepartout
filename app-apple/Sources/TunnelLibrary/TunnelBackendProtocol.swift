// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

public protocol TunnelBackendProtocol: AnyObject, Sendable {
    func start() async throws

    func stop() async

    func hold() async

    func sendMessage(_ messageData: Data) async throws -> Data?
}

extension SimpleConnectionDaemon: TunnelBackendProtocol {
    public func sendMessage(_ messageData: Data) async throws -> Data? {
        let input = try ABI.decode(Message.Input.self, from: messageData)
        let output = try await sendMessage(input)
        return try ABI.encode(output)
    }
}
