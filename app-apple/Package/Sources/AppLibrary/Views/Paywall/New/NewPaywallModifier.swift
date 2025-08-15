// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct NewPaywallModifier: ViewModifier {

    @EnvironmentObject
    private var iapManager: IAPManager

    @Binding
    private var reason: PaywallReason?

    private let onAction: ((PaywallModifier.Action, Profile?) -> Void)?

    private let onCancel: (() -> Void)?

    @State
    private var isConfirming = false

    @State
    private var isPurchasing = false

    public init(
        reason: Binding<PaywallReason?>,
        onAction: ((PaywallModifier.Action, Profile?) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        _reason = reason
        self.onAction = onAction
        self.onCancel = onCancel
    }

    public func body(content: Content) -> some View {
        content
            .alert(
                confirmationTitle,
                isPresented: $isConfirming,
                actions: confirmationActions,
                message: confirmationMessage
            )
            .themeModal(
                isPresented: $isPurchasing,
                options: .init(size: .custom(width: 400, height: 400)),
                content: modalDestination
            )
            .onChange(of: isPurchasing) {
                if !$0 {
                    reason = nil
                }
            }
            .onChange(of: reason) {
                guard let reason = $0 else {
                    return
                }
                Task {
                    if !iapManager.isEnabled {
                        pp_log_g(.App.iap, .info, "In-app purchases are disabled, enabling...")
                        await iapManager.enable()
                        guard !iapManager.isEligible(for: reason.requiredFeatures) else {
                            pp_log_g(.App.iap, .info, "Skipping paywall because eligible for features: \(reason.requiredFeatures)")
                            return
                        }
                    }
                    if reason.needsConfirmation {
                        isConfirming = true
                    } else {
                        guard !iapManager.isBeta else {
                            assertionFailure("Purchasing in beta?")
                            return
                        }
                        isPurchasing = true
                    }
                }
            }
    }
}

private extension NewPaywallModifier {
    func alertMessage(startingWith header: String, features: [String]) -> String {
        header + "\n\n" + features.joined(separator: "\n")
    }
}

// MARK: - Confirmation alert

private extension NewPaywallModifier {
    func title(forAction action: PaywallModifier.Action) -> String {
        switch action {
        case .cancel:
            return Strings.Global.Actions.cancel
        case .connect:
            return Strings.Global.Actions.connect
        case .purchase:
            return Strings.Global.Actions.purchase
        case .save:
            fatalError("Save action not handled")
        }
    }

    func confirmationActions() -> some View {
        reason.map { reason in
            Group {
                if let onAction {
                    Button(title(forAction: reason.action), role: .cancel) {
                        onAction(reason.action, reason.profile)
                    }
                }
                if !iapManager.isBeta {
                    Button(Strings.Global.Actions.purchase) {
                        isPurchasing = true
                    }
                }
            }
        }
    }

    var confirmationTitle: String {
        Strings.Views.Paywall.Alerts.Confirmation.title
    }

    func confirmationMessage() -> some View {
        Text(confirmationMessageString)
    }

    var confirmationMessageString: String {
        let V = Strings.Views.Paywall.Alerts.Confirmation.self
        var messages = [V.message]
        switch reason?.action {
        case .connect:
            messages.append(V.Message.connect(limitedMinutes))
        default:
            break
        }
        return alertMessage(
            startingWith: messages.joined(separator: " "),
            features: ineligibleFeatures
        )
    }
}

// MARK: - Paywall

private extension NewPaywallModifier {
    func modalDestination() -> some View {
        reason.map {
            PaywallCoordinator(
                isPresented: $isPurchasing,
                requiredFeatures: iapManager.excludingEligible(from: $0.requiredFeatures)
            )
        }
    }
}

// MARK: - Logic

private extension NewPaywallModifier {
    var ineligibleFeatures: [String] {
        guard let reason else {
            return []
        }
        return iapManager
            .excludingEligible(from: reason.requiredFeatures)
            .map(\.localizedDescription)
            .sorted()
    }

    var limitedMinutes: Int {
        iapManager.verificationDelayMinutes
    }
}

private extension IAPManager {
    func excludingEligible(from features: Set<AppFeature>) -> Set<AppFeature> {
        features.filter {
            !isEligible(for: $0)
        }
    }
}
