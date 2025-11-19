// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ThemeKeyValueModifier<T>: ViewModifier where T: Equatable {

    @ObservedObject
    private var store: KeyValueManager

    private let key: String

    @Binding
    private var value: T

    private let defaultValue: T

    public init(store: KeyValueManager, key: String, value: Binding<T>, defaultValue: T) {
        self.store = store
        self.key = key
        _value = value
        self.defaultValue = defaultValue
    }

    public func body(content: Content) -> some View {
        content
            .onLoad {
                value = store.object(forKey: key) ?? defaultValue
            }
            .onChange(of: value) {
                store.set($0, forKey: key)
            }
    }
}
