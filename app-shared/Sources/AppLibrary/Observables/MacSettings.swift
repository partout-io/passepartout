// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import AppKit
import CommonLibrary
import Partout
import ServiceManagement

@MainActor @Observable
public final class MacSettings {
    private let kvManager: KeyValueManager?

    private let appService: SMAppService?

    public var isStartedFromLoginItem: Bool {
        NSApp.isHidden
    }

    public var launchesOnLogin: Bool {
        didSet {
            guard let appService else { return }
            do {
                if launchesOnLogin {
                    try appService.register()
                } else {
                    try appService.unregister()
                }
            } catch {
                pp_log_g(.App.core, .error, "Unable to (un)register login item: \(error)")
            }
        }
    }

    public var keepsInMenu: Bool = false {
        didSet {
            kvManager?.set(keepsInMenu, forUIPreference: .keepsInMenu)
        }
    }

    public init() {
        kvManager = nil
        appService = nil

        launchesOnLogin = false
        keepsInMenu = false
    }

    public init(kvManager: KeyValueManager, loginItemId: String) {
        self.kvManager = kvManager
        appService = SMAppService.loginItem(identifier: loginItemId)

        launchesOnLogin = appService?.status == .enabled
        keepsInMenu = kvManager.bool(forUIPreference: .keepsInMenu)
    }
}

#endif
