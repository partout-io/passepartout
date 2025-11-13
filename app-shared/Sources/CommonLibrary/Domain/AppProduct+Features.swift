// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension AppProduct {
    public enum Essentials {
        static let all: [AppProduct] = [
            .Essentials.iOS_macOS,
            .Essentials.iOS,
            .Essentials.macOS
        ]
    }

    public enum Features {
        static let all: [AppProduct] = [
            .Features.allProviders,
            .Features.appleTV,
            .Features.networkSettings,
            .Features.trustedNetworks
        ]
    }

    public enum Complete {
        static let all: [AppProduct] = [
            .Complete.OneTime.lifetime,
            .Complete.Recurring.monthly,
            .Complete.Recurring.yearly
        ]
    }

    static let featurePrefix = "features."

    private init(featureId: String) {
        self.init(rawValue: "\(Self.featurePrefix)\(featureId)")!
    }

    var isFeature: Bool {
        rawValue.hasPrefix(Self.featurePrefix)
    }
}

// MARK: - Current

extension AppProduct.Essentials {

    // TODO: #128/notes, "Essentials" (Core) iOS/macOS/tvOS bundle (< Complete)
//    public static let allPlatforms = AppProduct(featureId: "essentials")

    public static let iOS_macOS = AppProduct(featureId: "full_multi_version")

    public static let iOS = AppProduct(featureId: "full_version")

    public static let macOS = AppProduct(featureId: "full_mac_version")
}

extension AppProduct.Features {
    public static let appleTV = AppProduct(featureId: "appletv")
}

extension AppProduct.Complete {
    public enum Recurring {
        public static let monthly = AppProduct(featureId: "full.monthly")

        public static let yearly = AppProduct(featureId: "full.yearly")
    }

    public enum OneTime {
        public static let lifetime = AppProduct(featureId: "full.lifetime")
    }
}

extension AppProduct {
    public var isComplete: Bool {
        switch self {
        case .Complete.Recurring.yearly,
                .Complete.Recurring.monthly,
                .Complete.OneTime.lifetime:
            return true
        default:
            return false
        }
    }

    public var isEssentials: Bool {
        switch self {
        case .Essentials.iOS,
                .Essentials.macOS,
                .Essentials.iOS_macOS:
            return true
        default:
            return false
        }
    }

    public var isRecurring: Bool {
        switch self {
        case .Complete.Recurring.monthly, .Complete.Recurring.yearly:
            return true
        default:
            return false
        }
    }
}

// MARK: - Discontinued

extension AppProduct.Features {
    public static let allProviders = AppProduct(featureId: "all_providers")

    public static let networkSettings = AppProduct(featureId: "network_settings")

    public static let trustedNetworks = AppProduct(featureId: "trusted_networks")
}
