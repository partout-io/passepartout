// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

extension View {

    @ViewBuilder
    public func themeModuleSection<Content>(if rows: [Any?]? = nil, header: String?, @ViewBuilder content: () -> Content) -> some View where Content: View {
        if let rows, rows.allSatisfy({ $0 == nil }) {
            EmptyView()
        } else {
            content()
                .themeSection(header: header)
        }
    }
}

#endif
