// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

public protocol TunnelBackendProtocol: AnyObject, Sendable {
    func start() async throws
    func stop() async
    func hold() async
    func sendMessage(_ messageData: Data) async throws -> Data?
}
