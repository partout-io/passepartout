// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ExtensiveLoggingToggle: View {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    public init() {
    }

    public var body: some View {
        Toggle(Strings.Views.Diagnostics.Rows.extensiveLogging, isOn: userPreferences.binding(\.extensiveLogging))
            .themeContainerEntry(subtitle: Strings.Views.Diagnostics.Rows.ExtensiveLogging.subtitle)
    }
}
