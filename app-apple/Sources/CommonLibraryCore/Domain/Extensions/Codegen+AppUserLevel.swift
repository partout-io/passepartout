// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI.AppUserLevel {
    public var isBeta: Bool {
        self == .beta
    }
}
