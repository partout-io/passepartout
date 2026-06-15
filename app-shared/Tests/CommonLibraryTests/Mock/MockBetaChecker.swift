// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

final class MockBetaChecker: BetaChecker, @unchecked Sendable {
    var isBeta = false

    func isBeta() async -> Bool {
        isBeta
    }
}
