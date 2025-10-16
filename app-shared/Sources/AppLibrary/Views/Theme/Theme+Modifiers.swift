// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

// keep sorted

// MARK: All platforms

extension View {
    public func themeAnimation<T>(on value: T, category: ThemeAnimationCategory) -> some View where T: Equatable {
        modifier(ThemeAnimationModifier(value: value, category: category))
    }

    public func themeBlurred(if condition: Bool) -> some View {
        opacity(condition ? 0.3 : 1.0)
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

    public func themeContainer(header: String? = nil, footer: String? = nil) -> some View {
        modifier(ThemeContainerModifier(header: header, footer: footer))
    }

    public func themeContainerEntry(header: String? = nil, subtitle: String? = nil, isAction: Bool = false) -> some View {
        modifier(ThemeContainerEntryModifier(header: header, subtitle: subtitle, isAction: isAction))
    }

    public func themeContainerWithSingleEntry(header: String? = nil, footer: String? = nil, isAction: Bool = false) -> some View {
#if os(macOS)
        themeContainerEntry(subtitle: footer, isAction: isAction)
            .themeContainer(header: header)
#else
        themeContainerEntry(header: header, subtitle: footer, isAction: isAction)
#endif
    }

    public func themeEmptyMessage(fullScreen: Bool = true) -> some View {
        modifier(ThemeEmptyMessageModifier(fullScreen: fullScreen))
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

    public func themeError(_ isError: Bool) -> some View {
        modifier(ThemeErrorModifier(isError: isError))
    }

    public func themeForm() -> some View {
        formStyle(.grouped)
    }

    public func themeKeyValue<T>(
        _ store: KeyValueManager,
        _ key: String,
        _ value: Binding<T>,
        default defaultValue: T
    ) -> some View where T: Equatable {
        modifier(ThemeKeyValueModifier(
            store: store,
            key: key,
            value: value,
            defaultValue: defaultValue
        ))
    }

    public func themeList() -> some View {
#if os(tvOS)
        listStyle(.grouped)
            .scrollClipDisabled()
#else
        self
#endif
    }

    public func themeManualInput(_ inputType: ThemeInputType) -> some View {
        modifier(ThemeManualInputModifier(inputType: inputType))
    }

    public func themeModal<Content>(
        isPresented: Binding<Bool>,
        options: ThemeModalOptions? = nil,
        @ViewBuilder content: @escaping () -> Content
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
        @ViewBuilder content: @escaping (T) -> Content
    ) -> some View where Content: View, T: Identifiable {
        modifier(ThemeItemModalModifier(
            item: item,
            options: options ?? ThemeModalOptions(),
            modal: content
        ))
    }

    @ViewBuilder
    public func themeMultiLine(_ isMultiLine: Bool) -> some View {
        if isMultiLine {
            multilineTextAlignment(.leading)
        } else {
            themeTruncating()
        }
    }

    public func themeNavigationDetail() -> some View {
#if os(iOS)
        navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }

    public func themeNavigationStack(
        closable: Bool = false,
        closeTitle: String? = nil,
        onClose: (() -> Void)? = nil,
        path: Binding<NavigationPath> = .constant(NavigationPath())
    ) -> some View {
        modifier(ThemeNavigationStackModifier(closable: closable, closeTitle: closeTitle, onClose: onClose, path: path))
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

    public func themeSection(header: String? = nil, footer: String? = nil) -> some View {
#if os(macOS)
        modifier(ThemeContainerModifier(header: header, footer: footer))
#else
        Section {
            self
        } header: {
            header.map(Text.init)
        } footer: {
            footer.map(Text.init)
        }
#endif
    }

    public func themeSubtitle() -> some View {
        foregroundStyle(.secondary)
            .font(.subheadline)
    }

    public func themeTrailingValue(_ value: CustomStringConvertible?, truncationMode: Text.TruncationMode = .tail) -> some View {
        modifier(ThemeTrailingValueModifier(value: value, truncationMode: truncationMode))
    }

    public func themeTruncating(_ mode: Text.TruncationMode = .middle) -> some View {
        lineLimit(1)
            .truncationMode(mode)
    }
}

// MARK: - iOS/macOS only

#if !os(tvOS)
extension View {
    public func themeGridCell() -> some View {
        modifier(ThemeGridCellModifier())
    }

    public func themeGridHeader<Header>(@ViewBuilder header: () -> Header) -> some View where Header: View {
        modifier(ThemeGridSectionModifier(header: header))
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

    public func themeWindow(width: CGFloat, height: CGFloat) -> some View {
        modifier(ThemeWindowModifier(size: .init(width: width, height: height)))
    }
}
#endif
