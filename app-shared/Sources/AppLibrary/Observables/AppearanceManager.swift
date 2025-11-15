// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import SwiftUI

@MainActor
public final class AppearanceManager: ObservableObject {
    private let kvManager: KeyValueManager

    @Published
    public var systemAppearance: SystemAppearance? {
        didSet {
            kvManager.set(systemAppearance?.rawValue, forUIPreference: .systemAppearance)
            apply()
        }
    }

    public init(kvManager: KeyValueManager) {
        self.kvManager = kvManager
        systemAppearance = kvManager.string(forUIPreference: .systemAppearance)
            .flatMap {
                SystemAppearance(rawValue: $0)
            }
    }
}

extension AppearanceManager {
    public func apply() {
#if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        guard let window = scene.keyWindow else {
            return
        }
        switch systemAppearance {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .none:
            window.overrideUserInterfaceStyle = .unspecified
        }
#elseif os(macOS)
        guard let app = NSApp else {
//            assertionFailure("NSApp is being used too early")
            return
        }
        switch systemAppearance {
        case .light:
            app.appearance = NSAppearance(named: .vibrantLight)
        case .dark:
            app.appearance = NSAppearance(named: .vibrantDark)
        case .none:
            app.appearance = nil
        }
#endif
    }
}
