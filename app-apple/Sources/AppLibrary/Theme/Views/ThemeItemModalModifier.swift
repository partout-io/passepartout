// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeItemModalModifier<Modal, T>: ViewModifier where Modal: View, T: Identifiable {

    @Environment(Theme.self)
    private var theme

    @Environment(\.colorScheme)
    private var colorScheme

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
