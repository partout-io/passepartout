// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI.AppProduct: ABI.AppFeatureProviding {
    public var features: [ABI.AppFeature] {
        switch self {

        // MARK: Current

        case .Essentials.iOS_macOS:
            return Array(ABI.AppFeature.essentialFeatures)

        case .Essentials.iOS:
#if os(iOS) || os(tvOS)
            return AppProduct.Essentials.iOS_macOS.features
#else
            return []
#endif
        case .Essentials.macOS:
#if os(macOS) || os(tvOS)
            return ABI.AppProduct.Essentials.iOS_macOS.features
#else
            return []
#endif
        case .Features.appleTV:
            return [.appleTV, .sharing]

        case .Complete.OneTime.lifetime, .Complete.Recurring.monthly, .Complete.Recurring.yearly:
            return ABI.AppFeature.allCases

        // MARK: Discontinued

        case .Features.allProviders:
            return [.providers]

        case .Features.networkSettings:
            return [.dns, .httpProxy, .routing]

        case .Features.trustedNetworks:
            return [.onDemand]

        default:
            return []
        }
    }
}
