// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

@BusinessActor
public protocol TunnelContextProtocol: Sendable {
    func start(isInteractive: Bool) async throws
    func stop() async
    func sendMessage(_ messageData: Data) async -> Data?
    nonisolated func cancel(_ error: Error?)
}

extension TunnelContextProtocol {
    public nonisolated func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        pspLog(category, level, message)
    }
}
