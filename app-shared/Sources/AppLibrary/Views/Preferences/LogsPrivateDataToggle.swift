// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct LogsPrivateDataToggle: View {

    @EnvironmentObject
    private var kvManager: KeyValueManager

    @State
    private var logsPrivateData = false

    public init() {
    }

    public var body: some View {
        Toggle(Strings.Views.Diagnostics.Rows.includePrivateData, isOn: $logsPrivateData)
            .themeKeyValue(kvManager, AppPreference.logsPrivateData.key, $logsPrivateData, default: false)
            .onChange(of: logsPrivateData) {
                kvManager.set($0, forAppPreference: .logsPrivateData)
            }
    }
}
