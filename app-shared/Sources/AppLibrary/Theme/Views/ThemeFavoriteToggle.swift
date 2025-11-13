// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ThemeFavoriteToggle<ID>: View where ID: Hashable {
    private let value: ID

    @ObservedObject
    private var selection: ObservableList<ID>

    @State
    private var hover: ID?

    public init(value: ID, selection: ObservableList<ID>) {
        self.value = value
        self.selection = selection
    }

    public var body: some View {
        Button {
            if selection.contains(value) {
                selection.remove(value)
            } else {
                selection.add(value)
            }
        } label: {
            ThemeImage(selection.contains(value) ? .favoriteOn : .favoriteOff)
                .opaque(opaque)
        }
#if os(macOS)
        .onHover {
            hover = $0 ? value : nil
        }
#endif
    }
}

private extension ThemeFavoriteToggle {
    var opaque: Bool {
#if os(macOS)
        selection.contains(value) || value == hover
#else
        true
#endif
    }
}
