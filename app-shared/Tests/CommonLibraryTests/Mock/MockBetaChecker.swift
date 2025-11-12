// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

final class MockBetaChecker: BetaChecker {
    var isBeta = false

    func isBeta() async -> Bool {
        isBeta
    }
}
