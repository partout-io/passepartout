// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

extension Theme {
    public func listSection<ItemView: View, T: EditableValue>(
        _ title: String?,
        footer: String? = nil,
        addTitle: String,
        originalItems: Binding<[T]>,
        emptyValue: (() async -> T)? = nil,
        canEmpty: Bool = true,
        @ViewBuilder itemLabel: @escaping (Bool, Binding<T>) -> ItemView
    ) -> some View {
        EditableListSection(
            title,
            footer: footer,
            addTitle: addTitle,
            originalItems: originalItems,
            emptyValue: emptyValue,
            canRemove: {
                canEmpty ? true : $0.count > 1
            },
            itemLabel: itemLabel,
            removeLabel: ThemeEditableListSection.RemoveLabel.init(action:),
            editLabel: ThemeEditableListSection.EditLabel.init
        )
    }
}

#endif
