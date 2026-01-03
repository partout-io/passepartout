// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct PurchaseRequiredView<Content>: View where Content: View {

    @EnvironmentObject
    private var iapManager: IAPManager

    let features: Set<ABI.AppFeature>?

    var force: Bool = false

    @ViewBuilder
    let content: () -> Content

    public var body: some View {
        if !iapManager.isBeta && (force || !isEligible) {
            content()
        }
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
        reason: Binding<PaywallReason?>
    ) {
        self.init(requiring: requiring?.features, reason: reason)
    }

    public init(
        requiring features: Set<ABI.AppFeature>?,
        reason: Binding<PaywallReason?>
    ) {
        self.features = features
        content = {
            PurchaseRequiredButton {
                reason.wrappedValue = .init(
                    nil,
                    requiredFeatures: features ?? [],
                    action: .purchase
                )
            }
        }
    }
}

// use for ad hoc feature paywalls, presents without confirmation
extension PurchaseRequiredView where Content == Button<Text> {
    public init(
        requiring features: Set<ABI.AppFeature>,
        reason: Binding<PaywallReason?>,
        title: String,
        force: Bool = true
    ) {
        self.features = features
        self.force = force
        content = {
            Button(title) {
                reason.wrappedValue = .init(
                    nil,
                    requiredFeatures: features,
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

    public init(requiring features: Set<ABI.AppFeature>?) {
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

    @Environment(Theme.self)
    private var theme

    public var body: some View {
        ThemeImage(.upgrade)
            .foregroundStyle(theme.upgradeColor)
            .help(Strings.Views.Ui.PurchaseRequired.Purchase.help)
            .imageScale(.large)
#if os(iOS)
            .padding(.leading, 4)
#endif
    }
}
