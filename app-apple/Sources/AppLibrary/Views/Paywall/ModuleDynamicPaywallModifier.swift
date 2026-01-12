// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ModuleDynamicPaywallModifier: ViewModifier {
    @Environment(ConfigObservable.self)
    private var configObservable

    @Binding
    private var paywallReason: PaywallReason?

    public init(reason: Binding<PaywallReason?>) {
        _paywallReason = reason
    }

    public func body(content: Content) -> some View {
        if configObservable.isUsingObservables {
            content.modifier(PaywallModifier(reason: $paywallReason))
        } else {
            content.modifier(LegacyPaywallModifier(reason: $paywallReason))
        }
    }
}
