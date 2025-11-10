// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI.AppProduct {
    public enum Essentials {
        static let all: [UI.AppProduct] = [
            .Essentials.iOS_macOS,
            .Essentials.iOS,
            .Essentials.macOS
        ]
    }

    public enum Features {
        static let all: [UI.AppProduct] = [
            .Features.allProviders,
            .Features.appleTV,
            .Features.networkSettings,
            .Features.trustedNetworks
        ]
    }

    public enum Complete {
        static let all: [UI.AppProduct] = [
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

extension UI.AppProduct.Essentials {

    // TODO: #128/notes, "Essentials" (Core) iOS/macOS/tvOS bundle (< Complete)
//    public static let allPlatforms = AppProduct(featureId: "essentials")

    public static let iOS_macOS = UI.AppProduct(featureId: "full_multi_version")

    public static let iOS = UI.AppProduct(featureId: "full_version")

    public static let macOS = UI.AppProduct(featureId: "full_mac_version")
}

extension UI.AppProduct.Features {
    public static let appleTV = UI.AppProduct(featureId: "appletv")
}

extension UI.AppProduct.Complete {
    public enum Recurring {
        public static let monthly = UI.AppProduct(featureId: "full.monthly")

        public static let yearly = UI.AppProduct(featureId: "full.yearly")
    }

    public enum OneTime {
        public static let lifetime = UI.AppProduct(featureId: "full.lifetime")
    }
}

extension UI.AppProduct {
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

extension UI.AppProduct.Features {
    public static let allProviders = UI.AppProduct(featureId: "all_providers")

    public static let networkSettings = UI.AppProduct(featureId: "network_settings")

    public static let trustedNetworks = UI.AppProduct(featureId: "trusted_networks")
}
