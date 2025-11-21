// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import AppKit
import CommonLibrary
import Foundation

extension SystemExtensionManager {
    public static let preferencesURL = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!

    public func openPreferences() {
        NSWorkspace.shared.open(Self.preferencesURL)
    }
}

#endif
