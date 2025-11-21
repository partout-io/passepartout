// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeBooleanModalModifier<Modal>: ViewModifier where Modal: View {

    @Environment(Theme.self)
    private var theme

    @Environment(\.colorScheme)
    private var colorScheme

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
