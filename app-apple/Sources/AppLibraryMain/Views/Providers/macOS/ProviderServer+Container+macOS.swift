// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import SwiftUI

extension ProviderServerView {
    struct ContainerView<Content, Filters>: View where Content: View, Filters: View {

        @ViewBuilder
        let content: Content

        @ViewBuilder
        let filters: Filters

        var body: some View {
            VStack {
                filters
                    .padding()
                content
            }
        }
    }
}

#endif
