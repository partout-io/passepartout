// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfilesLayoutPicker: View {

    @EnvironmentObject
    private var theme: Theme

    @Binding
    var layout: ABI.ProfilesLayout

    var body: some View {
        Picker(selection: $layout.animation(theme.animation(for: .profilesLayout))) {
            ForEach(ABI.ProfilesLayout.allCases, id: \.self, content: \.image)
        } label: {
            layout.image
        }
        .pickerStyle(.inline)
        // Workaround: https://stackoverflow.com/a/79676925/784615
        .fixedSize()
    }
}

private extension ABI.ProfilesLayout {
    var image: ThemeImage {
        switch self {
        case .list:
            return ThemeImage(.profilesList)

        case .grid:
            return ThemeImage(.profilesGrid)
        }
    }
}
