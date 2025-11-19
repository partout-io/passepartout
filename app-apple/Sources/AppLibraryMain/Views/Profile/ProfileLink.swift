// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ProfileRoute: Hashable {
    let wrapped: AnyHashable

    fileprivate init(_ wrapped: AnyHashable) {
        self.wrapped = wrapped
    }
}

struct ProfileLink<R>: View where R: Hashable {
    private let caption: String

    private let value: String?

    private let route: R

    init(_ caption: String, value: String? = nil, route: R) {
        self.caption = caption
        self.value = value
        self.route = route
    }

    var body: some View {
        NavigationLink(value: ProfileRoute(route)) {
            ThemeRow(caption, value: value)
        }
    }
}
