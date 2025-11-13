// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeNavigationStackModifier: ViewModifier {

    @Environment(\.dismiss)
    private var dismiss

    let closable: Bool

    var closeTitle: String?

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
                                ThemeCloseLabel(title: closeTitle)
                            }
                        }
                    }
                }
        }
    }
}
