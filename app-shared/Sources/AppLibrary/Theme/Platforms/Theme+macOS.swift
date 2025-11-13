// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import SwiftUI

extension Theme {
    public convenience init() {
        self.init(dummy: Void())
        animationCategories = [.diagnostics, .profiles, .providers]
    }
}

// MARK: - Shortcuts

extension View {
    public func themeLockScreen() -> some View {
        self
    }
}

// MARK: - Modifiers

extension ThemeWindowModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
    }
}

extension ThemeManualInputModifier {
    func body(content: Content) -> some View {
        content
            .autocorrectionDisabled()
    }
}

extension ThemeContainerModifier {
    func body(content: Content) -> some View {
        Section {
            content
            footer.map {
                Text($0)
                    .themeSubtitle()
            }
        } header: {
            header.map(Text.init)
        }
    }
}

extension ThemeContainerEntryModifier {
    func body(content: Content) -> some View {
        VStack {
            if !isAction {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            subtitle.map {
                Text($0)
                    .themeSubtitle()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if isAction {
                HStack {
                    Spacer()
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Views

extension ThemeTappableText {
    public var body: some View {
        commonView
            .buttonStyle(.plain)
            .cursor(.hand)
    }
}

extension ThemeTextField {
    public var body: some View {
        fieldView
    }
}

extension ThemeSecureField {
    public var body: some View {
        fieldView
    }
}

extension ThemeRemovableItemRow {
    func removeView() -> some View {
        Button(action: removeAction) {
            ThemeImage(.contextRemove)
        }
        .buttonStyle(.borderless)
    }
}

extension ThemeEditableListSection.RemoveLabel {
    public var body: some View {
        Button(action: action) {
            ThemeImage(.editableSectionRemove)
        }
        .buttonStyle(.borderless)
    }
}

extension ThemeEditableListSection.EditLabel {
    public var body: some View {
        ThemeImage(.editableSectionEdit)
    }
}

#endif
