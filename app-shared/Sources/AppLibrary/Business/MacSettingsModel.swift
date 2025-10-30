// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import AppKit
import CommonLibrary
import CommonUtils
import ServiceManagement

@MainActor
public final class MacSettingsModel: ObservableObject {
    private let kvManager: KeyValueManager?

    private let appService: SMAppService?

    public var isStartedFromLoginItem: Bool {
        NSApp.isHidden
    }

    public var launchesOnLogin: Bool {
        get {
            appService?.status == .enabled
        }
        set {
            objectWillChange.send()
            guard let appService else {
                return
            }
            do {
                if newValue {
                    try appService.register()
                } else {
                    try appService.unregister()
                }
            } catch {
                pp_log_g(.App.core, .error, "Unable to (un)register login item: \(error)")
            }
        }
    }

    public var keepsInMenu: Bool {
        get {
            kvManager?.bool(forUIPreference: .keepsInMenu) ?? false
        }
        set {
            objectWillChange.send()
            kvManager?.set(newValue, forUIPreference: .keepsInMenu)
        }
    }

    public init() {
        kvManager = nil
        appService = nil
    }

    public init(kvManager: KeyValueManager, loginItemId: String) {
        self.kvManager = kvManager
        appService = SMAppService.loginItem(identifier: loginItemId)
    }
}

#endif
