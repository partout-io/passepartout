// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import SwiftUI

// https://stackoverflow.com/questions/65355696/how-to-programatically-open-settings-preferences-window-in-a-macos-swiftui-app/72803389#72803389
public struct CompatibleSettingsLink<Label>: View where Label: View {
    private let label: () -> Label

    public init(label: @escaping () -> Label) {
        self.label = label
    }

    public var body: some View {
        SettingsLink(label: label)
    }
}

#endif
