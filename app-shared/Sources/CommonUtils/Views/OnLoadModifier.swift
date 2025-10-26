// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct OnLoadModifier: ViewModifier {
    public let onLoad: () -> Void

    @State
    private var didAppear = false

    public init(onLoad: @escaping () -> Void) {
        self.onLoad = onLoad
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                guard !didAppear else {
                    return
                }
                didAppear = true
                onLoad()
            }
    }
}

extension View {
    public func onLoad(perform: @escaping () -> Void) -> some View {
        modifier(OnLoadModifier(onLoad: perform))
    }
}
