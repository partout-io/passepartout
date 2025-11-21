// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import SwiftUI

extension Theme {
    public convenience init() {
        self.init(dummy: ())
        animationCategories = [.diagnostics, .modules, .profiles, .providers]
    }
}

// MARK: - Shortcuts

extension View {
    public func themePopover<Content>(
        isPresented: Binding<Bool>,
        size: ThemeModalSize = .medium,
        content: @escaping () -> Content
    ) -> some View where Content: View {
        modifier(ThemeBooleanPopoverModifier(
            isPresented: isPresented,
            size: size,
            popover: content
        ))
    }

    public func themeLockScreen() -> some View {
        modifier(ThemeLockScreenModifier {
            ThemeFullScreenView {
                ThemeLogo()
            }
        })
    }
}

// MARK: - Presentation modifiers

struct ThemeBooleanPopoverModifier<Popover>: ViewModifier, SizeClassProviding where Popover: View {

    @Environment(Theme.self)
    private var theme

    @Environment(\.horizontalSizeClass)
    var hsClass

    @Environment(\.verticalSizeClass)
    var vsClass

    @Binding
    var isPresented: Bool

    let size: ThemeModalSize

    @ViewBuilder
    let popover: Popover

    func body(content: Content) -> some View {
        let modalSize = theme.modalSize(size)
        if isBigDevice {
            content
                .popover(isPresented: $isPresented) {
                    popover
                        .frame(minWidth: modalSize.width, minHeight: modalSize.height)
                        .themeLockScreen()
                }
        } else {
            content
                .sheet(isPresented: $isPresented) {
                    popover
                        .themeLockScreen()
                }
        }
    }
}

// MARK: - Content modifiers

extension ThemeWindowModifier {
    func body(content: Content) -> some View {
        content
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
        content
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

extension ThemeTappableText {
    public var body: some View {
        commonView
            .foregroundStyle(.primary)
    }
}

extension ThemeTextField {
    public var body: some View {
        labeledView
    }
}

extension ThemeSecureField {
    public var body: some View {
        labeledView
    }
}

extension ThemeRemovableItemRow {
    func removeView() -> some View {
        EmptyView()
    }
}

extension ThemeEditableListSection.RemoveLabel {
    public var body: some View {
        EmptyView()
    }
}

extension ThemeEditableListSection.EditLabel {
    public var body: some View {
        EmptyView()
    }
}

#endif
