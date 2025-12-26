// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import AppKit
import CommonLibrary
import ServiceManagement

@MainActor @Observable
public final class MacSettings {
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

    public init() {
        appService = nil
        launchesOnLogin = false
    }

    public init(loginItemId: String) {
        appService = SMAppService.loginItem(identifier: loginItemId)
        launchesOnLogin = appService?.status == .enabled
    }
}

#endif
