// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct LogsPrivateDataToggle: View {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    @Environment(TunnelObservable.self)
    private var tunnel

    public init() {
    }

    private var hasEnabledProfiles: Bool {
        tunnel.activeProfiles.values.contains { $0.isEnabled }
    }

    public var body: some View {
        Toggle(Strings.Views.Diagnostics.Rows.includePrivateData, isOn: userPreferences.binding(\.logsPrivateData))
            .disabled(hasEnabledProfiles)
            .themeContainerEntry(subtitle: hasEnabledProfiles
                ? Strings.Views.Diagnostics.Rows.IncludePrivateData.disableProfiles
                : Strings.Views.Diagnostics.Rows.IncludePrivateData.subtitle)
    }
}
