// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import SwiftUI

extension EnvironmentValues {
    public var isUITesting: Bool {
        get {
            self[IsUITestingKey.self]
        }
        set {
            self[IsUITestingKey.self] = newValue
        }
    }

    public var appConfiguration: ABI.AppConfiguration {
        get {
            self[AppConfigurationKey.self]
        }
        set {
            self[AppConfigurationKey.self] = newValue
        }
    }
}

private struct IsUITestingKey: EnvironmentKey {
    static let defaultValue = false
}

private struct AppConfigurationKey: EnvironmentKey {
    static let defaultValue = Resources.newAppConfiguration(
        distributionTarget: .appStore,
        buildTarget: .app
    )
}
