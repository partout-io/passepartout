// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

extension View {
    public func uiAccessibility(_ info: AccessibilityInfo) -> some View {
        accessibilityIdentifier(info.id)
    }
}
