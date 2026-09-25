// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary
import PartoutCore
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

    public var appImportExport: AppImportExport {
        get {
            self[AppImportExportKey.self]
        }
        set {
            self[AppImportExportKey.self] = newValue
        }
    }

    public var wireGuardKeyGenerator: WireGuardKeyGenerator {
        get {
            self[WireGuardKeyGeneratorKey.self]
        }
        set {
            self[WireGuardKeyGeneratorKey.self] = newValue
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

private struct AppImportExportKey: EnvironmentKey {
    static let defaultValue: AppImportExport = .dummy
}

private struct WireGuardKeyGeneratorKey: EnvironmentKey {
    static let defaultValue: WireGuardKeyGenerator = FakeWireGuardKeyGenerator()
}
