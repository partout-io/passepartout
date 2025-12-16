// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)

@testable import CommonLibraryApple
@testable import CommonLibraryCore
import Testing

@MainActor
struct IAPManagerNewSuggestionsTests {
    @Test
    func givenFree_thenSuggestsEssentialsAllAndPlatform() async {
        let sut = await IAPManager(products: [])
        #expect(sut.essentialProducts(on: .iOS) == [
            .Essentials.iOS_macOS,
            .Essentials.iOS
        ])
        #expect(sut.essentialProducts(on: .macOS) == [
            .Essentials.iOS_macOS,
            .Essentials.macOS
        ])
    }

    @Test
    func givenEssentialsiOS_thenSuggestsEssentialsmacOS() async {
        let sut = await IAPManager(products: [.Essentials.iOS])
        #expect(sut.essentialProducts(on: .iOS) == [])
        #expect(sut.essentialProducts(on: .macOS) == [
            .Essentials.macOS
        ])
    }

    @Test
    func givenEssentialsmacOS_thenSuggestsEssentialsiOS() async {
        let sut = await IAPManager(products: [.Essentials.macOS])
        #expect(sut.essentialProducts(on: .iOS) == [
            .Essentials.iOS
        ])
        #expect(sut.essentialProducts(on: .macOS) == [])
    }

    @Test
    func givenEssentialsiOSmacOS_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Essentials.iOS, .Essentials.macOS])
        #expect(sut.essentialProducts(on: .iOS) == [])
        #expect(sut.essentialProducts(on: .macOS) == [])
    }

    @Test
    func givenEssentialsAll_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Essentials.iOS_macOS])
        #expect(sut.essentialProducts(on: .iOS) == [])
        #expect(sut.essentialProducts(on: .macOS) == [])
    }

    @Test
    func givenAppleTV_thenSuggestsEssentialsAllAndPlatform() async {
        let sut = await IAPManager(products: [.Features.appleTV])
        #expect(sut.essentialProducts(on: .iOS) == [
            .Essentials.iOS_macOS,
            .Essentials.iOS
        ])
        #expect(sut.essentialProducts(on: .macOS) == [
            .Essentials.iOS_macOS,
            .Essentials.macOS
        ])
    }

    @Test
    func givenFeature_thenSuggestsEssentialsAllAndPlatform() async {
        let sut = await IAPManager(products: [.Features.trustedNetworks])
        #expect(sut.essentialProducts(on: .iOS) == [
            .Essentials.iOS_macOS,
            .Essentials.iOS
        ])
        #expect(sut.essentialProducts(on: .macOS) == [
            .Essentials.iOS_macOS,
            .Essentials.macOS
        ])
    }

    @Test
    func givenLifetime_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Complete.OneTime.lifetime])
        #expect(sut.essentialProducts(on: .iOS) == [])
        #expect(sut.essentialProducts(on: .macOS) == [])
    }

    @Test
    func givenRecurringMonthly_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Complete.Recurring.monthly])
        #expect(sut.essentialProducts(on: .iOS) == [])
        #expect(sut.essentialProducts(on: .macOS) == [])
    }

    @Test
    func givenRecurringYearly_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Complete.Recurring.yearly])
        #expect(sut.essentialProducts(on: .iOS) == [])
        #expect(sut.essentialProducts(on: .macOS) == [])
    }

    @Test
    func givenFree_whenWithComplete_thenSuggestsEssentialsAndComplete() async {
        let sut = await IAPManager(products: [])
        #expect(sut.essentialProducts(
            on: .iOS,
            including: [.complete, .singlePlatformEssentials]
        ) == [
            .Essentials.iOS_macOS,
            .Essentials.iOS,
            .Complete.Recurring.yearly,
            .Complete.Recurring.monthly,
            .Complete.OneTime.lifetime
        ])
        #expect(sut.essentialProducts(
            on: .macOS,
            including: [.complete, .singlePlatformEssentials]
        ) == [
            .Essentials.iOS_macOS,
            .Essentials.macOS,
            .Complete.Recurring.yearly,
            .Complete.Recurring.monthly,
            .Complete.OneTime.lifetime
        ])
    }

    @Test
    func givenOldProducts_whenWithComplete_thenSuggestsEssentialsAndComplete() async {
        let sut = await IAPManager(products: [.Features.trustedNetworks])
        #expect(sut.essentialProducts(
            on: .iOS,
            including: [.complete, .singlePlatformEssentials]
        ) == [
            .Essentials.iOS_macOS,
            .Essentials.iOS,
            .Complete.OneTime.lifetime,
            .Complete.Recurring.monthly,
            .Complete.Recurring.yearly
        ])
        #expect(sut.essentialProducts(
            on: .macOS,
            including: [.complete, .singlePlatformEssentials]
        ) == [
            .Essentials.iOS_macOS,
            .Essentials.macOS,
            .Complete.OneTime.lifetime,
            .Complete.Recurring.monthly,
            .Complete.Recurring.yearly
        ])
    }

    @Test
    func givenNewProducts_whenWithComplete_thenSuggestsEssentials() async {
        let sut = await IAPManager(products: [.Features.appleTV])
        #expect(sut.essentialProducts(
            on: .iOS,
            including: [.complete, .singlePlatformEssentials]
        ) == [
            .Essentials.iOS_macOS,
            .Essentials.iOS
        ])
        #expect(sut.essentialProducts(
            on: .macOS,
            including: [.complete, .singlePlatformEssentials]
        ) == [
            .Essentials.iOS_macOS,
            .Essentials.macOS
        ])
    }
}

// MARK: - Suggestions (Non-essential)

extension IAPManagerTests {
    @Test
    func givenFree_whenSuggestMixedFeatures_thenSuggestsEssentials() async {
        let sut = await IAPManager(products: [])
        let features: Set<ABI.AppFeature> = [.appleTV, .dns]
        #expect(sut.mixedProducts(for: features, on: .iOS) == [
            .Essentials.iOS_macOS,
            .Essentials.iOS,
            .Features.appleTV
        ])
        #expect(sut.mixedProducts(for: features, on: .macOS) == [
            .Essentials.iOS_macOS,
            .Essentials.macOS,
            .Features.appleTV
        ])
    }

    @Test
    func givenFree_whenSuggestNonEssentialFeature_thenDoesNotSuggestEssentials() async {
        let sut = await IAPManager(products: [])
        let features: Set<ABI.AppFeature> = [.appleTV]
        #expect(sut.mixedProducts(for: features, on: .iOS) == [
            .Features.appleTV
        ])
        #expect(sut.mixedProducts(for: features, on: .macOS) == [
            .Features.appleTV
        ])
    }

    @Test
    func givenFree_whenSuggestNonEssentialImplyingEssentialFeature_thenDoesNotSuggestEssentials() async {
        let sut = await IAPManager(products: [])
        let features: Set<ABI.AppFeature> = [.appleTV, .sharing]
        #expect(sut.mixedProducts(for: features, on: .iOS) == [
            .Features.appleTV
        ])
        #expect(sut.mixedProducts(for: features, on: .macOS) == [
            .Features.appleTV
        ])
    }
}

// MARK: -

private extension IAPManager {
    func essentialProducts(
        on platform: Platform,
        including: Set<SuggestionInclusion> = [.singlePlatformEssentials]
    ) -> Set<ABI.AppProduct> {
        suggestedProducts(for: ABI.AppFeature.essentialFeatures, on: platform, including: including)
    }

    func mixedProducts(
        for features: Set<ABI.AppFeature>,
        on platform: Platform,
        including: Set<SuggestionInclusion> = [.singlePlatformEssentials]
    ) -> Set<ABI.AppProduct> {
        suggestedProducts(for: features, on: platform, including: including)
    }
}

#endif
