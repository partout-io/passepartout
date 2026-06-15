// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension IAPManager {
    public enum Platform {
        case iOS

        case macOS

        case tvOS
    }

    public func suggestedProducts(
        for features: Set<ABI.AppFeature>,
        hints: Set<ABI.StoreProductHint>?
    ) -> Set<ABI.AppProduct> {
#if os(iOS)
        suggestedProducts(for: features, on: .iOS, hints: hints)
#elseif os(macOS)
        suggestedProducts(for: features, on: .macOS, hints: hints)
#elseif os(tvOS)
        suggestedProducts(for: features, on: .tvOS, hints: hints)
#else
        []
#endif
    }
}

// for testing
extension IAPManager {
    // Suggest the minimum set of products for the given required features
    func suggestedProducts(
        for features: Set<ABI.AppFeature>,
        on platform: Platform,
        hints: Set<ABI.StoreProductHint>?,
        asserting: Bool = false
    ) -> Set<ABI.AppProduct> {
        // Include all by default
        let hints = hints ?? [.complete, .singlePlatformEssentials]

        guard !purchasedProducts.contains(where: \.isComplete) else {
            if asserting {
                assertionFailure("Suggesting products to complete version purchaser?")
            }
            return []
        }

        var suggested: Set<ABI.AppProduct> = []

        // Prioritize eligible features from non-essential products
        let nonEssentialProducts = features.flatMap(\.nonEssentialProducts)
        suggested.formUnion(nonEssentialProducts)
        let nonEssentialEligibleFeatures = Set(nonEssentialProducts.flatMap(\.features))

        //
        // Suggest essential packages if:
        //
        // - Never purchased any
        // - Non-essential eligible features don't include required essential features
        //
        let essentialFeatures = features.filter(\.isEssential)
        if !didPurchaseEssentials(on: platform) &&
            !nonEssentialEligibleFeatures.isSuperset(of: essentialFeatures) {
            switch platform {
            case .iOS:
                // Suggest both platforms if never purchased
                if !purchasedProducts.contains(.Essentials.macOS) {
                    suggested.insert(.Essentials.iOS_macOS)
                }
                // Suggest iOS to former macOS purchasers
                let suggestsSinglePlatform = hints.contains(.singlePlatformEssentials) || purchasedProducts.contains(.Essentials.macOS)
                if suggestsSinglePlatform && !purchasedProducts.contains(.Essentials.iOS) {
                    suggested.insert(.Essentials.iOS)
                }
            case .macOS:
                // Suggest both platforms if never purchased
                if !purchasedProducts.contains(.Essentials.iOS) {
                    suggested.insert(.Essentials.iOS_macOS)
                }
                // Suggest macOS to former iOS purchasers
                let suggestsSinglePlatform = hints.contains(.singlePlatformEssentials) || purchasedProducts.contains(.Essentials.iOS)
                if suggestsSinglePlatform && !purchasedProducts.contains(.Essentials.macOS) {
                    suggested.insert(.Essentials.macOS)
                }
            case .tvOS:
                // Suggest both platforms if never purchased
                if !purchasedProducts.contains(where: \.isEssentials) {
                    suggested.insert(.Essentials.iOS_macOS)
                }
            }
        }

        let suggestsComplete: Bool
        switch platform {
        case .tvOS:
            //
            // "Essential" features are not accessible from the
            // TV, therefore selling the "Complete" packages is misleading
            // for TV-only customers. Only offer them if some "essential"
            // feature is required, because it means that the iOS/macOS app
            // is also installed
            //
            // TODO: #103/partout, set always true because all features will be accessible on TV by importing a .json created elsewhere
            suggestsComplete = !essentialFeatures.isEmpty
        default:
            suggestsComplete = true
        }

        // Suggest complete packages if eligible
        if hints.contains(.complete) && suggestsComplete && isEligibleForComplete {
            suggested.insert(.Complete.Recurring.yearly)
            suggested.insert(.Complete.Recurring.monthly)
            suggested.insert(.Complete.OneTime.lifetime)
        }

        // Strip purchased (paranoid check)
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
