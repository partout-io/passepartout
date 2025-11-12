// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

public typealias PaywallAction = PaywallModifier.Action

public typealias PaywallReason = PaywallModifier.Reason

extension PaywallModifier {
    public enum Action {
        case cancel

        case connect

        case purchase

        case save
    }

    public struct Reason: Hashable {
        public let profile: Profile?

        public let requiredFeatures: Set<AppFeature>

        public let action: Action

        public init(
            _ profile: Profile?,
            requiredFeatures: Set<AppFeature>,
            action: Action
        ) {
            self.profile = profile
            self.requiredFeatures = requiredFeatures
            self.action = action
        }

        public var needsConfirmation: Bool {
            action != .purchase
        }
    }
}
