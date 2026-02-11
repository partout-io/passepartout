// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension IAPManager {
    public enum Platform {
        case iOS

        case macOS

        case tvOS
    }

    public enum SuggestionInclusion {
        case complete

        case singlePlatformEssentials
    }

    public func suggestedProducts(
        for features: Set<ABI.AppFeature>,
        including: Set<SuggestionInclusion>
    ) -> Set<ABI.AppProduct> {
#if os(iOS)
        suggestedProducts(for: features, on: .iOS, including: including)
#elseif os(macOS)
        suggestedProducts(for: features, on: .macOS, including: including)
#elseif os(tvOS)
        suggestedProducts(for: features, on: .tvOS, including: including)
#else
        []
#endif
    }
}

// for testing
extension IAPManager {

    // suggest the minimum set of products for the given required features
    func suggestedProducts(
        for features: Set<ABI.AppFeature>,
        on platform: Platform,
        including: Set<SuggestionInclusion>,
        asserting: Bool = false
    ) -> Set<ABI.AppProduct> {
        guard !purchasedProducts.contains(where: \.isComplete) else {
            if asserting {
                assertionFailure("Suggesting products to complete version purchaser?")
            }
            return []
        }

        var suggested: Set<ABI.AppProduct> = []

        // prioritize eligible features from non-essential products
        let nonEssentialProducts = features.flatMap(\.nonEssentialProducts)
        suggested.formUnion(nonEssentialProducts)
        let nonEssentialEligibleFeatures = Set(nonEssentialProducts.flatMap(\.features))

        //
        // suggest essential packages if:
        //
        // - never purchased any
        // - non-essential eligible features don't include required essential features
        //
        let essentialFeatures = features.filter(\.isEssential)
        if !didPurchaseEssentials(on: platform) &&
            !nonEssentialEligibleFeatures.isSuperset(of: essentialFeatures) {
            switch platform {
            case .iOS:
                // suggest both platforms if never purchased
                if !purchasedProducts.contains(.Essentials.macOS) {
                    suggested.insert(.Essentials.iOS_macOS)
                }
                // suggest iOS to former macOS purchasers
                let suggestsSinglePlatform = including.contains(.singlePlatformEssentials) || purchasedProducts.contains(.Essentials.macOS)
                if suggestsSinglePlatform && !purchasedProducts.contains(.Essentials.iOS) {
                    suggested.insert(.Essentials.iOS)
                }
            case .macOS:
                // suggest both platforms if never purchased
                if !purchasedProducts.contains(.Essentials.iOS) {
                    suggested.insert(.Essentials.iOS_macOS)
                }
                // suggest macOS to former iOS purchasers
                let suggestsSinglePlatform = including.contains(.singlePlatformEssentials) || purchasedProducts.contains(.Essentials.iOS)
                if suggestsSinglePlatform && !purchasedProducts.contains(.Essentials.macOS) {
                    suggested.insert(.Essentials.macOS)
                }
            case .tvOS:
                // suggest both platforms if never purchased
                if !purchasedProducts.contains(where: \.isEssentials) {
                    suggested.insert(.Essentials.iOS_macOS)
                }
            }
        }

        let suggestsComplete: Bool
        switch platform {
        case .tvOS:
            //
            // "essential" features are not accessible from the
            // TV, therefore selling the "complete" packages is misleading
            // for TV-only customers. only offer them if some "essential"
            // feature is required, because it means that the iOS/macOS app
            // is also installed
            //
            // TODO: #103/partout, set always true because all features will be accessible on TV by importing a .json created elsewhere
            suggestsComplete = !essentialFeatures.isEmpty
        default:
            suggestsComplete = true
        }

        // suggest complete packages if eligible
        if including.contains(.complete) && suggestsComplete && isEligibleForComplete {
            suggested.insert(.Complete.Recurring.yearly)
            suggested.insert(.Complete.Recurring.monthly)
            suggested.insert(.Complete.OneTime.lifetime)
        }

        // strip purchased (paranoid check)
        suggested.subtract(purchasedProducts)

        return suggested
    }

    func didPurchaseEssentials(on platform: Platform) -> Bool {
        switch platform {
        case .iOS:
            return purchasedProducts.contains(.Essentials.iOS) || purchasedProducts.contains(.Essentials.iOS_macOS)
        case .macOS:
            return purchasedProducts.contains(.Essentials.macOS) || purchasedProducts.contains(.Essentials.iOS_macOS)
        case .tvOS:
            return purchasedProducts.contains(where: \.isEssentials)
        }
    }
}
