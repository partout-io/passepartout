// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor @Observable
public final class ConfigObservable {
    private let configManager: ConfigManager

    public init(configManager: ConfigManager) {
        self.configManager = configManager
    }

    public var canImportToTV: Bool {
        configManager.canImportToTV
    }

    public var canSendToTV: Bool {
        configManager.canSendToTV
    }
}
