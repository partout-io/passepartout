// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)

@testable import CommonLibraryApple
@testable import CommonLibraryCore
import XCTest

@MainActor
final class IAPManagerNewSuggestionsTests: XCTestCase {
    func test_givenFree_thenSuggestsEssentialsAllAndPlatform() async {
        let sut = await IAPManager(products: [])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [
            .Essentials.iOS_macOS,
            .Essentials.iOS
        ])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [
            .Essentials.iOS_macOS,
            .Essentials.macOS
        ])
    }

    func test_givenEssentialsiOS_thenSuggestsEssentialsmacOS() async {
        let sut = await IAPManager(products: [.Essentials.iOS])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [
            .Essentials.macOS
        ])
    }

    func test_givenEssentialsmacOS_thenSuggestsEssentialsiOS() async {
        let sut = await IAPManager(products: [.Essentials.macOS])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [
            .Essentials.iOS
        ])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [])
    }

    func test_givenEssentialsiOSmacOS_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Essentials.iOS, .Essentials.macOS])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [])
    }

    func test_givenEssentialsAll_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Essentials.iOS_macOS])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [])
    }

    func test_givenAppleTV_thenSuggestsEssentialsAllAndPlatform() async {
        let sut = await IAPManager(products: [.Features.appleTV])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [
            .Essentials.iOS_macOS,
            .Essentials.iOS
        ])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [
            .Essentials.iOS_macOS,
            .Essentials.macOS
        ])
    }

    func test_givenFeature_thenSuggestsEssentialsAllAndPlatform() async {
        let sut = await IAPManager(products: [.Features.trustedNetworks])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [
            .Essentials.iOS_macOS,
            .Essentials.iOS
        ])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [
            .Essentials.iOS_macOS,
            .Essentials.macOS
        ])
    }

    func test_givenLifetime_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Complete.OneTime.lifetime])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [])
    }

    func test_givenRecurringMonthly_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Complete.Recurring.monthly])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [])
    }

    func test_givenRecurringYearly_thenSuggestsNothing() async {
        let sut = await IAPManager(products: [.Complete.Recurring.yearly])
        XCTAssertEqual(sut.essentialProducts(on: .iOS), [])
        XCTAssertEqual(sut.essentialProducts(on: .macOS), [])
    }

    func test_givenFree_whenWithComplete_thenSuggestsEssentialsAndComplete() async {
        let sut = await IAPManager(products: [])
        XCTAssertEqual(sut.essentialProducts(
            on: .iOS,
            including: [.complete, .singlePlatformEssentials]
        ), [
            .Essentials.iOS_macOS,
            .Essentials.iOS,
            .Complete.Recurring.yearly,
            .Complete.Recurring.monthly,
            .Complete.OneTime.lifetime
        ])
        XCTAssertEqual(sut.essentialProducts(
            on: .macOS,
            including: [.complete, .singlePlatformEssentials]
        ), [
            .Essentials.iOS_macOS,
            .Essentials.macOS,
            .Complete.Recurring.yearly,
            .Complete.Recurring.monthly,
            .Complete.OneTime.lifetime
        ])
    }

    func test_givenOldProducts_whenWithComplete_thenSuggestsEssentialsAndComplete() async {
        let sut = await IAPManager(products: [.Features.trustedNetworks])
        XCTAssertEqual(sut.essentialProducts(
            on: .iOS,
            including: [.complete, .singlePlatformEssentials]
        ), [
            .Essentials.iOS_macOS,
            .Essentials.iOS,
            .Complete.OneTime.lifetime,
            .Complete.Recurring.monthly,
            .Complete.Recurring.yearly
        ])
        XCTAssertEqual(sut.essentialProducts(
            on: .macOS,
            including: [.complete, .singlePlatformEssentials]
        ), [
            .Essentials.iOS_macOS,
            .Essentials.macOS,
            .Complete.OneTime.lifetime,
            .Complete.Recurring.monthly,
            .Complete.Recurring.yearly
        ])
    }

    func test_givenNewProducts_whenWithComplete_thenSuggestsEssentials() async {
        let sut = await IAPManager(products: [.Features.appleTV])
        XCTAssertEqual(sut.essentialProducts(
            on: .iOS,
            including: [.complete, .singlePlatformEssentials]
        ), [
            .Essentials.iOS_macOS,
            .Essentials.iOS
        ])
        XCTAssertEqual(sut.essentialProducts(
            on: .macOS,
            including: [.complete, .singlePlatformEssentials]
        ), [
            .Essentials.iOS_macOS,
            .Essentials.macOS
        ])
    }
}

// MARK: - Suggestions (Non-essential)

extension IAPManagerTests {
    func test_givenFree_whenSuggestMixedFeatures_thenSuggestsEssentials() async {
        let sut = await IAPManager(products: [])
        let features: Set<ABI.AppFeature> = [.appleTV, .dns]
        XCTAssertEqual(sut.mixedProducts(for: features, on: .iOS), [
            .Essentials.iOS_macOS,
            .Essentials.iOS,
            .Features.appleTV
        ])
        XCTAssertEqual(sut.mixedProducts(for: features, on: .macOS), [
            .Essentials.iOS_macOS,
            .Essentials.macOS,
            .Features.appleTV
        ])
    }

    func test_givenFree_whenSuggestNonEssentialFeature_thenDoesNotSuggestEssentials() async {
        let sut = await IAPManager(products: [])
        let features: Set<ABI.AppFeature> = [.appleTV]
        XCTAssertEqual(sut.mixedProducts(for: features, on: .iOS), [
            .Features.appleTV
        ])
        XCTAssertEqual(sut.mixedProducts(for: features, on: .macOS), [
            .Features.appleTV
        ])
    }

    func test_givenFree_whenSuggestNonEssentialImplyingEssentialFeature_thenDoesNotSuggestEssentials() async {
        let sut = await IAPManager(products: [])
        let features: Set<ABI.AppFeature> = [.appleTV, .sharing]
        XCTAssertEqual(sut.mixedProducts(for: features, on: .iOS), [
            .Features.appleTV
        ])
        XCTAssertEqual(sut.mixedProducts(for: features, on: .macOS), [
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
