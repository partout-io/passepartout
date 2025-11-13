// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import CommonLibrary
import SwiftUI

public struct ThemeCopiableText<Value, ValueView>: View where Value: CustomStringConvertible, ValueView: View {

    @EnvironmentObject
    private var theme: Theme

    private let title: String?

    private let value: Value

    private let isMultiLine: Bool

    private let valueView: (Value) -> ValueView

    public init(
        _ title: String? = nil,
        value: Value,
        isMultiLine: Bool = true,
        valueView: @escaping (Value) -> ValueView
    ) {
        self.title = title
        self.value = value
        self.isMultiLine = isMultiLine
        self.valueView = valueView
    }

    public var body: some View {
        HStack {
            if let title {
                Text(title)
                Spacer()
            }
            valueView(value)
                .foregroundStyle(title == nil ? theme.titleColor : theme.valueColor)
                .themeMultiLine(isMultiLine)
            if title == nil {
                Spacer()
            }
            Button {
                copyToPasteboard(value.description)
            } label: {
                ThemeImage(.copy)
            }
            // XXX: #584, necessary to avoid cell selection
            .buttonStyle(.borderless)
        }
    }
}

public struct ThemeTruncatedText: View {
    let title: String

    public var body: some View {
        Text(title)
            .themeTruncating(.middle)
    }
}

extension ThemeCopiableText where Value == String, ValueView == ThemeTruncatedText {
    public init(
        _ title: String? = nil,
        value: Value,
        isMultiLine: Bool = true
    ) {
        self.init(title, value: value, isMultiLine: isMultiLine) {
            ThemeTruncatedText(title: $0)
        }
    }
}

#endif
