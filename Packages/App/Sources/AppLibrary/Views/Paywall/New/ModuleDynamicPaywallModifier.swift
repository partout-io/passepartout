// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ModuleDynamicPaywallModifier: ViewModifier {

    @EnvironmentObject
    private var configManager: ConfigManager

    @Binding
    private var paywallReason: PaywallReason?

    public init(reason: Binding<PaywallReason?>) {
        _paywallReason = reason
    }

    public func body(content: Content) -> some View {
        if configManager.isActive(.newPaywall) {
            content.modifier(NewPaywallModifier(reason: $paywallReason))
        } else {
            content.modifier(PaywallModifier(reason: $paywallReason))
        }
    }
}
