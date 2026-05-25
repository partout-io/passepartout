// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI.AppPreferencesProtocol {
    @BusinessActor
    public mutating func constrainRelaxedVerification(to configManager: ConfigManager) {
        guard configManager.isActive(.allowsRelaxedVerification) else {
            relaxedVerification = false
            return
        }
        if configManager.isActive(.forcesRelaxedVerification) {
            relaxedVerification = true
        }
    }
}
