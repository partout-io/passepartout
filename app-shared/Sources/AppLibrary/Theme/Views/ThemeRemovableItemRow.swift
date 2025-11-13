// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public struct ThemeRemovableItemRow<ItemView>: View where ItemView: View {
    private let isEditing: Bool

    @ViewBuilder
    private let itemView: () -> ItemView

    let removeAction: () -> Void

    public init(
        isEditing: Bool,
        @ViewBuilder itemView: @escaping () -> ItemView,
        removeAction: @escaping () -> Void
    ) {
        self.isEditing = isEditing
        self.itemView = itemView
        self.removeAction = removeAction
    }

    public var body: some View {
        RemovableItemRow(
            isEditing: isEditing,
            itemView: itemView,
            removeView: removeView
        )
    }
}

struct RemovableItemRow<ItemView, RemoveView>: View where ItemView: View, RemoveView: View {
    let isEditing: Bool

    let itemView: () -> ItemView

    let removeView: () -> RemoveView

    init(
        isEditing: Bool,
        @ViewBuilder itemView: @escaping () -> ItemView,
        @ViewBuilder removeView: @escaping () -> RemoveView
    ) {
        self.isEditing = isEditing
        self.itemView = itemView
        self.removeView = removeView
    }

    var body: some View {
        HStack {
            if isEditing {
                removeView()
            }
            itemView()
        }
    }
}

#endif
