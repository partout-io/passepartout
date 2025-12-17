// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import AppResources
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

    public var logFormatterBlock: LogFormatterBlock {
        get {
            self[LogFormatterBlockKey.self]
        }
        set {
            self[LogFormatterBlockKey.self] = newValue
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

private struct LogFormatterBlockKey: EnvironmentKey {
    static let defaultValue: @Sendable (ABI.AppLogLine) -> String = \.message
}
