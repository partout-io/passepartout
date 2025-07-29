// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ConfigManager {
    public var canSendToTV: Bool {
        isActive(.newPaywall) && isActive(.sendToTV)
    }
}
