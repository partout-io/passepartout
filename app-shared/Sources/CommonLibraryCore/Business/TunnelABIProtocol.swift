// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore_C

@MainActor
public protocol TunnelABIProtocol: AppLogger, Sendable {
    func start(isInteractive: Bool) async throws
    func stop() async
    func sendMessage(_ messageData: Data) async -> Data?
    nonisolated func cancel(_ error: Error?)
}
