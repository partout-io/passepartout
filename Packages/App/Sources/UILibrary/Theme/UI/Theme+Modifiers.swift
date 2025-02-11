//
//  Theme+Modifiers.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/1/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonLibrary
import CommonUtils
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
import SwiftUI

// MARK: Shortcuts

public struct ThemeModalOptions: Hashable {
    public var size: ThemeModalSize

    public var isFixedWidth: Bool

    public var isFixedHeight: Bool

    public var isInteractive: Bool

    public init(
        size: ThemeModalSize = .medium,
        isFixedWidth: Bool = false,
        isFixedHeight: Bool = false,
        isInteractive: Bool = true
    ) {
        self.size = size
        self.isFixedWidth = isFixedWidth
        self.isFixedHeight = isFixedHeight
        self.isInteractive = isInteractive
    }
}

public enum ThemeModalSize: Hashable {
    case small

    case medium

    case large

    case custom(width: CGFloat, height: CGFloat)
}

extension View {
    public func themeModal<Content>(
        isPresented: Binding<Bool>,
        options: ThemeModalOptions? = nil,
        content: @escaping () -> Content
    ) -> some View where Content: View {
        modifier(ThemeBooleanModalModifier(
            isPresented: isPresented,
            options: options ?? ThemeModalOptions(),
            modal: content
        ))
    }

    public func themeModal<Content, T>(
        item: Binding<T?>,
        options: ThemeModalOptions? = nil,
        content: @escaping (T) -> Content
    ) -> some View where Content: View, T: Identifiable {
        modifier(ThemeItemModalModifier(
            item: item,
            options: options ?? ThemeModalOptions(),
            modal: content
        ))
    }

    public func themeConfirmation(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        modifier(ThemeConfirmationModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            isDestructive: isDestructive,
            action: action
        ))
    }

    public func themeNavigationStack(
        closable: Bool = false,
        onClose: (() -> Void)? = nil,
        path: Binding<NavigationPath> = .constant(NavigationPath())
    ) -> some View {
        modifier(ThemeNavigationStackModifier(closable: closable, onClose: onClose, path: path))
    }

    @ViewBuilder
    public func themeNavigationStack(
        if condition: Bool,
        closable: Bool = false,
        onClose: (() -> Void)? = nil,
        path: Binding<NavigationPath> = .constant(NavigationPath())
    ) -> some View {
        if condition {
            modifier(ThemeNavigationStackModifier(closable: closable, onClose: onClose, path: path))
        } else {
            self
        }
    }

    public func themeList() -> some View {
#if os(tvOS)
        listStyle(.grouped)
            .scrollClipDisabled()
#else
        self
#endif
    }

    public func themeForm() -> some View {
        formStyle(.grouped)
    }

    public func themeManualInput() -> some View {
        modifier(ThemeManualInputModifier())
    }

    public func themeSection(header: String? = nil, footer: String? = nil, forcesFooter: Bool = false) -> some View {
        modifier(ThemeSectionWithHeaderFooterModifier(header: header, footer: footer, forcesFooter: forcesFooter))
    }

    public func themeSectionWithSingleRow(header: String? = nil, footer: String, above: Bool = false) -> some View {
        Group {
            if above {
                EmptyView()
                    .themeRowWithSubtitle(footer) // macOS

                self
            } else {
                themeRowWithSubtitle(footer) // macOS
            }
        }
        .themeSection(header: header, footer: footer) // iOS/tvOS
    }

    // subtitle is hidden on iOS/tvOS
    public func themeRowWithSubtitle(_ subtitle: String?) -> some View {
        themeRowWithSubtitle {
            subtitle.map(Text.init)
        }
    }

    public func themeRowWithSubtitle<Subtitle>(_ subtitle: () -> Subtitle) -> some View where Subtitle: View {
        modifier(ThemeRowWithSubtitleModifier(subtitle: subtitle))
    }

    public func themeSubtitle() -> some View {
        foregroundStyle(.secondary)
            .font(.subheadline)
    }

    public func themeNavigationDetail() -> some View {
#if os(iOS)
        navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }

    @ViewBuilder
    public func themeMultiLine(_ isMultiLine: Bool) -> some View {
        if isMultiLine {
            multilineTextAlignment(.leading)
        } else {
            themeTruncating()
        }
    }

    public func themeTruncating(_ mode: Text.TruncationMode = .middle) -> some View {
        lineLimit(1)
            .truncationMode(mode)
    }

    public func themeEmptyMessage(fullScreen: Bool = true) -> some View {
        modifier(ThemeEmptyMessageModifier(fullScreen: fullScreen))
    }

    public func themeError(_ isError: Bool) -> some View {
        modifier(ThemeErrorModifier(isError: isError))
    }

    public func themeAnimation<T>(on value: T, category: ThemeAnimationCategory) -> some View where T: Equatable {
        modifier(ThemeAnimationModifier(value: value, category: category))
    }

    @ViewBuilder
    public func themeEmpty(if isEmpty: Bool, message: String) -> some View {
        if !isEmpty {
            self
        } else {
            Text(message)
                .themeEmptyMessage()
        }
    }

    @ViewBuilder
    public func themeEmpty<EmptyContent>(
        if isEmpty: Bool,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) -> some View where EmptyContent: View {
        if !isEmpty {
            self
        } else {
            emptyContent()
        }
    }

    public func themeProgress(if isProgressing: Bool) -> some View {
        modifier(ThemeProgressViewModifier(isProgressing: isProgressing) {
            EmptyView()
        })
    }

    public func themeProgress(
        if isProgressing: Bool,
        isEmpty: Bool,
        emptyMessage: String
    ) -> some View {
        modifier(ThemeProgressViewModifier(isProgressing: isProgressing, isEmpty: isEmpty) {
            Text(emptyMessage)
                .themeEmptyMessage()
        })
    }

    public func themeProgress<EmptyContent>(
        if isProgressing: Bool,
        isEmpty: Bool,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) -> some View where EmptyContent: View {
        modifier(ThemeProgressViewModifier(isProgressing: isProgressing, isEmpty: isEmpty, emptyContent: emptyContent))
    }

    public func themeTrailingValue(_ value: CustomStringConvertible?, truncationMode: Text.TruncationMode = .tail) -> some View {
        modifier(ThemeTrailingValueModifier(value: value, truncationMode: truncationMode))
    }

#if !os(tvOS)
    public func themeWindow(width: CGFloat, height: CGFloat) -> some View {
        modifier(ThemeWindowModifier(size: .init(width: width, height: height)))
    }

    public func themeGridHeader<Header>(@ViewBuilder header: () -> Header) -> some View where Header: View {
        modifier(ThemeGridSectionModifier(header: header))
    }

    public func themeGridCell() -> some View {
        modifier(ThemeGridCellModifier())
    }

    public func themeHoverListRow() -> some View {
        modifier(ThemeHoverListRowModifier())
    }

    @ViewBuilder
    public func themeTip(_ tip: AppTip) -> some View {
        if #available(iOS 18, macOS 15, *) {
            popoverTip(tip)
        } else {
            self
        }
    }

    public func themeTip<Label>(
        _ text: String,
        edge: Edge,
        width: Double = 150.0,
        alignment: Alignment = .center,
        label: @escaping () -> Label = {
            ThemeImage(.tip)
                .imageScale(.large)
        }
    ) -> some View where Label: View {
        modifier(ThemeTipModifier(
            text: text,
            edge: edge,
            width: width,
            alignment: alignment,
            label: label
        ))
    }
#endif
}

// MARK: - Presentation modifiers

extension ThemeModalSize {
    var defaultSize: CGSize {
        switch self {
        case .small:
            return CGSize(width: 300, height: 300)

        case .medium:
            return CGSize(width: 550, height: 350)

        case .large:
            return CGSize(width: 800, height: 500)

        case .custom(let width, let height):
            return CGSize(width: width, height: height)
        }
    }
}

struct ThemeBooleanModalModifier<Modal>: ViewModifier where Modal: View {

    @EnvironmentObject
    private var theme: Theme

    @Binding
    var isPresented: Bool

    let options: ThemeModalOptions

    let modal: () -> Modal

    func body(content: Content) -> some View {
        let modalSize = theme.modalSize(options.size)
        _ = modalSize
        return content
            .sheet(isPresented: $isPresented) {
                modal()
#if os(macOS)
                    .frame(
                        minWidth: modalSize.width,
                        maxWidth: options.isFixedWidth ? modalSize.width : nil,
                        minHeight: modalSize.height,
                        maxHeight: options.isFixedHeight ? modalSize.height : nil
                    )
#endif
                    .interactiveDismissDisabled(!options.isInteractive)
                    .themeLockScreen()
            }
    }
}

struct ThemeItemModalModifier<Modal, T>: ViewModifier where Modal: View, T: Identifiable {

    @EnvironmentObject
    private var theme: Theme

    @Binding
    var item: T?

    let options: ThemeModalOptions

    let modal: (T) -> Modal

    func body(content: Content) -> some View {
        let modalSize = theme.modalSize(options.size)
        _ = modalSize
        return content
            .sheet(item: $item) {
                modal($0)
#if os(macOS)
                    .frame(
                        minWidth: modalSize.width,
                        maxWidth: options.isFixedWidth ? modalSize.width : nil,
                        minHeight: modalSize.height,
                        maxHeight: options.isFixedHeight ? modalSize.height : nil
                    )
#endif
                    .interactiveDismissDisabled(!options.isInteractive)
                    .themeLockScreen()
            }
    }
}

struct ThemeConfirmationModifier: ViewModifier {

    @Binding
    var isPresented: Bool

    let title: String

    let message: String?

    let isDestructive: Bool

    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(title, isPresented: $isPresented, titleVisibility: .visible) {
                Button(Strings.Theme.Confirmation.ok, role: isDestructive ? .destructive : nil, action: action)
                Text(Strings.Theme.Confirmation.cancel)
            } message: {
                Text(message ?? Strings.Theme.Confirmation.message)
            }
    }
}

struct ThemeNavigationStackModifier: ViewModifier {

    @Environment(\.dismiss)
    private var dismiss

    let closable: Bool

    let onClose: (() -> Void)?

    @Binding
    var path: NavigationPath

    func body(content: Content) -> some View {
        NavigationStack(path: $path) {
            content
                .toolbar {
                    if closable {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                if let onClose {
                                    onClose()
                                } else {
                                    dismiss()
                                }
                            } label: {
                                ThemeCloseLabel()
                            }
                        }
                    }
                }
        }
    }
}

// MARK: - Content modifiers

struct ThemeManualInputModifier: ViewModifier {
}

struct ThemeSectionWithHeaderFooterModifier: ViewModifier {
    let header: String?

    let footer: String?

    let forcesFooter: Bool
}

struct ThemeRowWithSubtitleModifier<Subtitle>: ViewModifier where Subtitle: View {

    @ViewBuilder
    let subtitle: Subtitle
}

struct ThemeEmptyMessageModifier: ViewModifier {

    @EnvironmentObject
    private var theme: Theme

    let fullScreen: Bool

    func body(content: Content) -> some View {
        VStack {
            if fullScreen {
                Spacer()
            }
            content
                .font(theme.emptyMessageFont)
                .foregroundStyle(theme.emptyMessageColor)
            if fullScreen {
                Spacer()
            }
        }
    }
}

struct ThemeErrorModifier: ViewModifier {

    @EnvironmentObject
    private var theme: Theme

    let isError: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isError ? theme.errorColor : theme.titleColor)
    }
}

struct ThemeAnimationModifier<T>: ViewModifier where T: Equatable {

    @EnvironmentObject
    private var theme: Theme

    let value: T

    let category: ThemeAnimationCategory

    func body(content: Content) -> some View {
        content
            .animation(theme.animation(for: category), value: value)
    }
}

struct ThemeProgressViewModifier<EmptyContent>: ViewModifier where EmptyContent: View {
    let isProgressing: Bool

    var isEmpty: Bool?

    var emptyContent: (() -> EmptyContent)?

    func body(content: Content) -> some View {
        ZStack {
            content
                .opaque(!isProgressing && isEmpty != true)

            if isProgressing {
                ThemeProgressView()
            } else if let isEmpty, let emptyContent, isEmpty {
                emptyContent()
            }
        }
    }
}

struct ThemeTrailingValueModifier: ViewModifier {
    let value: CustomStringConvertible?

    let truncationMode: Text.TruncationMode

    func body(content: Content) -> some View {
        LabeledContent {
            if let value {
                Text(value.description)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(truncationMode)
            }
        } label: {
            content
        }
    }
}

#if !os(tvOS)

struct ThemeWindowModifier: ViewModifier {
    let size: CGSize
}

struct ThemeGridSectionModifier<Header>: ViewModifier where Header: View {

    @EnvironmentObject
    private var theme: Theme

    @ViewBuilder
    let header: Header

    func body(content: Content) -> some View {
        header
            .font(theme.gridHeaderStyle)
            .fontWeight(theme.relevantWeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading)
            .padding(.bottom, theme.gridHeaderBottom)

        content
            .padding(.bottom)
    }
}

struct ThemeGridCellModifier: ViewModifier {

    @EnvironmentObject
    private var theme: Theme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(theme.gridCellColor)
            .clipShape(.rect(cornerRadius: theme.gridRadius))
    }
}

struct ThemeHoverListRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxHeight: .infinity)
            .listRowInsets(.init())
    }
}

struct ThemeLockScreenModifier<LockedContent>: ViewModifier where LockedContent: View {

    @AppStorage(UIPreference.locksInBackground.key)
    private var locksInBackground = false

    @EnvironmentObject
    private var theme: Theme

    @ViewBuilder
    let lockedContent: () -> LockedContent

    func body(content: Content) -> some View {
        LockableView(
            locksInBackground: locksInBackground,
            content: {
                content
            },
            lockedContent: lockedContent,
            unlockBlock: Self.unlockScreenBlock
        )
    }

    private static func unlockScreenBlock() async -> Bool {
        let context = LAContext()
        let policy: LAPolicy = .deviceOwnerAuthentication
        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            return true
        }
        do {
            let isAuthorized = try await context.evaluatePolicy(
                policy,
                localizedReason: Strings.Theme.LockScreen.reason(Strings.Unlocalized.appName)
            )
            return isAuthorized
        } catch {
            return false
        }
    }
}

struct ThemeTipModifier<Label>: ViewModifier where Label: View {
    let text: String

    let edge: Edge

    let width: Double

    let alignment: Alignment

    let label: () -> Label

    @State
    private var isPresenting = false

    func body(content: Content) -> some View {
        HStack {
            content
            Button {
                isPresenting = true
            } label: {
                label()
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $isPresenting, arrowEdge: edge) {
                VStack {
                    Text(text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .frame(width: width, alignment: alignment)
                }
                .padding(12)
            }
        }
    }
}

#endif
