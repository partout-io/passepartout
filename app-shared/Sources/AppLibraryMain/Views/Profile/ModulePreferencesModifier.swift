// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ModulePreferencesModifier: ViewModifier {

    @EnvironmentObject
    private var preferencesManager: PreferencesManager

    private let moduleId: UUID

    @ObservedObject
    private var preferences: ModulePreferences

    public init(moduleId: UUID, preferences: ModulePreferences) {
        self.moduleId = moduleId
        self.preferences = preferences
    }

    public func body(content: Content) -> some View {
        content
            .onLoad {
                do {
                    let repository = try preferencesManager.preferencesRepository(forModuleWithId: moduleId)
                    preferences.setRepository(repository)
                } catch {
                    pp_log_g(.App.core, .error, "Unable to load preferences for module \(moduleId): \(error)")
                }
            }
            .onDisappear {
                do {
                    try preferences.save()
                } catch {
                    pp_log_g(.App.core, .error, "Unable to save preferences for module \(moduleId): \(error)")
                }
            }
    }
}
