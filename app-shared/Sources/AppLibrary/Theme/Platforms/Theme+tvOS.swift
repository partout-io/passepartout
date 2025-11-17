// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(tvOS)

import SwiftUI

extension Theme {
    public convenience init() {
        self.init(dummy: Void())
        relevantWeight = .bold
        secondaryWeight = .light
    }
}

// MARK: - Shortcuts

extension View {
    public func themeLockScreen() -> some View {
        self
    }

    public func themeGradient() -> some View {
        modifier(ThemeGradientModifier())
    }
}

// MARK: - Modifiers

private struct ThemeGradientModifier: ViewModifier {

    @Environment(Theme.self)
    private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.darkAccentColor.opacity(0.6).gradient)
    }
}

extension ThemeManualInputModifier {
    func body(content: Content) -> some View {
        content
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(inputType.keyboardType)
    }
}

extension ThemeContainerModifier {
    func body(content: Content) -> some View {
        Section {
            content
        } header: {
            header.map(Text.init)
        } footer: {
            footer.map(Text.init)
        }
    }
}

extension ThemeContainerEntryModifier {
    func body(content: Content) -> some View {
        Section {
            content
        } header: {
            header.map(Text.init)
        } footer: {
            subtitle.map(Text.init)
        }
    }
}

// MARK: - Views

extension ThemeTextField {
    public var body: some View {
        TextField(title ?? "", text: $text)
            .themeManualInput(inputType)
    }
}

extension ThemeSecureField {
    public var body: some View {
        SecureField(title ?? "", text: $text)
    }
}

#endif
