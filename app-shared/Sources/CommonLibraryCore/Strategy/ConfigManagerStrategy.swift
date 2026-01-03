// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol ConfigManagerStrategy: Sendable {
    func bundle() async throws -> ABI.ConfigBundle
}
