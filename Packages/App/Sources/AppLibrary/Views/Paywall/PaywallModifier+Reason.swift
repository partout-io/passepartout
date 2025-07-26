// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

public typealias PaywallReason = PaywallModifier.Reason

extension PaywallModifier {
    public enum Action {
        case connect

        case save

        case purchase
    }

    public struct Reason: Hashable {
        public let profile: Profile?

        public let requiredFeatures: Set<AppFeature>

        public let suggestedProducts: Set<AppProduct>?

        public let action: Action

        public init(
            _ profile: Profile?,
            requiredFeatures: Set<AppFeature>,
            suggestedProducts: Set<AppProduct>? = nil,
            action: Action
        ) {
            self.profile = profile
            self.requiredFeatures = requiredFeatures
            self.suggestedProducts = suggestedProducts
            self.action = action
        }

        public var needsConfirmation: Bool {
            action != .purchase
        }
    }
}
