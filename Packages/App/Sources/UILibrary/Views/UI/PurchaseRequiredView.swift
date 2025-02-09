//
//  PurchaseRequiredView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/17/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonLibrary
import CommonUtils
import PassepartoutKit
import SwiftUI

public struct PurchaseRequiredView<Content>: View where Content: View {

    @EnvironmentObject
    private var iapManager: IAPManager

    let features: Set<AppFeature>?

    var force: Bool = false

    @ViewBuilder
    let content: () -> Content

    public var body: some View {
        content()
            .opaque(force || !isEligible)
            .if(!iapManager.isBeta)
    }
}

private extension PurchaseRequiredView {
    var isEligible: Bool {
        if let features {
            return iapManager.isEligible(for: features)
        }
        return true
    }
}

// MARK: - Initializers

// use for essential paywall, presents without confirmation
extension PurchaseRequiredView where Content == PurchaseRequiredButton {
    public init(
        for requiring: AppFeatureRequiring?,
        reason: Binding<PaywallReason?>,
        suggesting products: Set<AppProduct>? = nil
    ) {
        self.init(requiring: requiring?.features, reason: reason, suggesting: products)
    }

    public init(
        requiring features: Set<AppFeature>?,
        reason: Binding<PaywallReason?>,
        suggesting products: Set<AppProduct>? = nil
    ) {
        self.features = features
        content = {
            PurchaseRequiredButton {
                reason.wrappedValue = .init(
                    nil,
                    requiredFeatures: features ?? [],
                    suggestedProducts: products,
                    action: .purchase
                )
            }
        }
    }
}

// use for ad hoc feature paywalls, presents without confirmation
extension PurchaseRequiredView where Content == Button<Text> {
    public init(
        requiring features: Set<AppFeature>,
        reason: Binding<PaywallReason?>,
        title: String,
        suggesting products: Set<AppProduct>
    ) {
        self.features = features
        force = true
        content = {
            Button(title) {
                reason.wrappedValue = .init(
                    nil,
                    requiredFeatures: features,
                    suggestedProducts: products,
                    action: .purchase
                )
            }
        }
    }
}

// use for upgrade icon only
extension PurchaseRequiredView where Content == PurchaseRequiredImage {
    public init(for requiring: AppFeatureRequiring?) {
        self.init(requiring: requiring?.features)
    }

    public init(requiring features: Set<AppFeature>?) {
        self.features = features
        content = {
            PurchaseRequiredImage()
        }
    }
}

// MARK: - Labels

public struct PurchaseRequiredButton: View {
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            PurchaseRequiredImage()
        }
        .buttonStyle(.plain)
        .cursor(.hand)
    }
}

public struct PurchaseRequiredImage: View {

    @EnvironmentObject
    private var theme: Theme

    public var body: some View {
        ThemeImage(.upgrade)
            .foregroundStyle(theme.upgradeColor)
            .help(Strings.Views.Ui.PurchaseRequired.Purchase.help)
#if os(macOS)
            .imageScale(.large)
#endif
    }
}
