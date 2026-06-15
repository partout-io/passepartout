// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol BetaChecker: Sendable {
    func isBeta() async -> Bool
}
