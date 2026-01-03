// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeNameSection: View {

    @Binding
    private var name: String

    private let placeholder: String

    private let footer: String?

    public init(name: Binding<String>, placeholder: String, footer: String? = nil) {
        _name = name
        self.placeholder = placeholder
        self.footer = footer
    }

    public var body: some View {
        debugChanges()
        return Group {
            ThemeTextField(Strings.Global.Nouns.name, text: $name, placeholder: placeholder)
                .labelsHidden()
        }
        .themeSection(header: Strings.Global.Nouns.name, footer: footer)
    }
}

// MARK: - Previews

#Preview {
    struct ContentView: View {

        @State
        private var name = ""

        var body: some View {
            Form {
                ThemeNameSection(
                    name: $name,
                    placeholder: "My name",
                    footer: "Some footer description."
                )
            }
            .themeForm()
        }
    }

    return ContentView()
        .withMockEnvironment()
}
