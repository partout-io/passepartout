// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import AppKit

@MainActor
public final class AppWindow {
    public static let shared = AppWindow()

    public var isVisible: Bool {
        get {
            NSApp.activationPolicy() == .regular && window?.isVisible == true
        }
        set {
            // this code is unused, show() is more solid
            NSApp.setActivationPolicy(newValue ? .regular : .accessory)
            if newValue {
                NSApp.activate(ignoringOtherApps: true)
                window?.makeKeyAndOrderFront(self)
            } else {
                window?.close()
            }
        }
    }

    private init() {
    }

    public func show(completion: (() -> Void)? = nil) async throws {
        if isVisible {
            return
        }
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = false
        try await NSWorkspace.shared.openApplication(at: url, configuration: config)
    }
}

private extension AppWindow {
    var window: NSWindow? {
        NSApp.windows.first(where: \.isWindow)
    }
}

private extension NSWindow {
    var isWindow: Bool {
        !className.contains("NSStatusBar")
    }
}

#endif
