// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension KeyValueStore {
    @MainActor
    func constrainRelaxedVerification(to configManager: ConfigManager) {
        guard configManager.isActive(.allowsRelaxedVerification) else {
            set(false, forAppPreference: .relaxedVerification)
            return
        }
        set(true, forAppPreference: .relaxedVerification)
    }
}
