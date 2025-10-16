// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeImageLabel<Title>: View where Title: View {

    @EnvironmentObject
    private var theme: Theme

    private let name: Theme.ImageName

    private let inForm: Bool

    @ViewBuilder
    private let title: () -> Title

    public init(_ name: Theme.ImageName, inForm: Bool = false, @ViewBuilder title: @escaping () -> Title) {
        self.name = name
        self.inForm = inForm
        self.title = title
    }

    public var body: some View {
        Label(title: title) {
            ThemeImage(name)
#if os(iOS)
                .scaleEffect(inForm ? 0.9 : 1.0, anchor: .center)
#endif
        }
    }
}

extension ThemeImageLabel where Title == Text {
    public init(_ title: String, inForm: Bool = false, _ name: Theme.ImageName) {
        self.init(name, inForm: inForm) {
            Text(title)
        }
    }
}
