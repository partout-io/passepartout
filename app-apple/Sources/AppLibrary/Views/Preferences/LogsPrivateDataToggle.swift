// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct LogsPrivateDataToggle: View {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    public init() {
    }

    public var body: some View {
        Toggle(Strings.Views.Diagnostics.Rows.includePrivateData, isOn: userPreferences.binding(\.logsPrivateData))
    }
}
