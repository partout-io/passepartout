// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import SwiftUI

extension ProviderServerView {
    struct ContainerView<Content, Filters>: View where Content: View, Filters: View {

        @ViewBuilder
        let content: Content

        @ViewBuilder
        let filters: Filters

        var body: some View {
            content
                .modifier(FiltersItemModifier {
                    filters
                })
        }
    }
}

private struct FiltersItemModifier<FiltersContent>: ViewModifier where FiltersContent: View {

    @ViewBuilder
    let filtersContent: FiltersContent

    @State
    private var isPresented = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                Button {
                    isPresented = true
                } label: {
                    ThemeImage(.filters)
                }
                .themePopover(
                    isPresented: $isPresented,
                    size: .custom(width: 400, height: 400),
                    content: filtersPopover
                )
            }
    }

    func filtersPopover() -> some View {
        filtersContent
            .navigationTitle(Strings.Global.Nouns.filters)
            .themeNavigationDetail()
            .themeNavigationStack(closable: true) {
                isPresented = false
            }
            .presentationDetents([.medium])
    }
}

#endif
