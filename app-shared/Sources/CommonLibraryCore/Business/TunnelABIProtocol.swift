// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore_C

@MainActor
public protocol TunnelABIProtocol: Sendable {
    func start() async throws
    func stop() async
}
