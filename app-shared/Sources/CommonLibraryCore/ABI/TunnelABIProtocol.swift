// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore_C
import MiniFoundation

@MainActor
public protocol TunnelABIProtocol: AppABILoggerProtocol, Sendable {
    func start(isInteractive: Bool) async throws
    func stop() async
    func sendMessage(_ messageData: Data) async -> Data?
    nonisolated func cancel(_ error: Error?)
}
