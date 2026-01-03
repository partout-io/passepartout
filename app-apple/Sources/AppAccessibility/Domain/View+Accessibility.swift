// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

extension View {
    public func uiAccessibility(_ info: AccessibilityInfo) -> some View {
        accessibilityIdentifier(info.id)
    }
}
