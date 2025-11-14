// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

extension View {
    func forMainButton(withColor color: Color, focused: Bool, disabled: Bool) -> some View {
        padding(.vertical, 25)
            .background(disabled ? .gray : color)
            .cornerRadius(50)
            .font(.title3)
            .foregroundColor(disabled ? .white.opacity(0.6) : .white)
            .overlay(
                RoundedRectangle(cornerRadius: 50)
                    .fill(.white.opacity(focused ? 0.3 : 0.0))
            )
            .scaleEffect(focused ? 1.05 : 1.0)
    }
}
