// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Foundation
import XCTest

@MainActor
final class IAPManagerTests: XCTestCase {
    private let olderBuildNumber = 500

    private let defaultBuildNumber = 1000

    private let newerBuildNumber = 1500
}

extension AppRelease {
    static let target = Self("older", build: 1000)
}

// MARK: - Actions

extension IAPManagerTests {
    func test_givenProducts_whenFetchAppProducts_thenReturnsCorrespondingInAppProducts() async throws {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)

        let appProducts: [ABI.AppProduct] = [
            .Essentials.iOS_macOS,
            .Donations.huge
        ]
        let inAppProducts = try await sut.purchasableProducts(for: appProducts)
        inAppProducts.enumerated().forEach {
            XCTAssertEqual($0.element.productIdentifier, appProducts[$0.offset].rawValue)
        }
    }

    func test_givenProducts_whenPurchase_thenIsAddedToPurchasedProducts() async throws {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [])
        let sut = IAPManager(receiptReader: reader)

        let appleTV: ABI.AppProduct = .Features.appleTV
        XCTAssertFalse(sut.purchasedProducts.contains(appleTV))
        do {
            let purchasable = try await sut.purchasableProducts(for: [appleTV])
            let purchasableAppleTV = try XCTUnwrap(purchasable.first)
            let result = try await sut.purchase(purchasableAppleTV)
            if result == .done {
                XCTAssertTrue(sut.purchasedProducts.contains(appleTV))
            } else {
                XCTFail("Unexpected purchase() result: \(result)")
            }
        } catch {
            XCTFail("Unexpected purchase() failure: \(error)")
        }
    }
}

// MARK: - Build products

extension IAPManagerTests {
    func test_givenBuildProducts_whenOlder_thenEssentialsVersion() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: olderBuildNumber, identifiers: [])
        let sut = IAPManager(receiptReader: reader) { [defaultBuildNumber] purchase in
            if purchase.buildNumber <= defaultBuildNumber {
                return [.Essentials.iOS_macOS]
            }
            return []
        }
        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    func test_givenBuildProducts_whenNewer_thenFreeVersion() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: newerBuildNumber, products: [])
        let sut = IAPManager(receiptReader: reader) { [defaultBuildNumber] purchase in
            if purchase.buildNumber <= defaultBuildNumber {
                return [.Essentials.iOS_macOS]
            }
            return []
        }
        await sut.reloadReceipt()
        XCTAssertFalse(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    func test_givenBuildProducts_whenFutureRelease_thenFreeVersion() async {
        let reader = FakeAppReceiptReader()
        let purchase = OriginalPurchase(buildNumber: .max, purchaseDate: .distantFuture)
        await reader.setReceipt(withPurchase: purchase, products: [])
        let sut = IAPManager(receiptReader: reader) { purchase in
            if purchase.isUntil(.target) {
                return [.Features.appleTV]
            }
            return []
        }
        await sut.reloadReceipt()
        XCTAssertFalse(sut.isEligible(for: .appleTV))
    }

    func test_givenBuildProducts_whenPastRelease_thenFreeVersion() async {
        let reader = FakeAppReceiptReader()
        let purchase = OriginalPurchase(buildNumber: 0, purchaseDate: .distantPast)
        await reader.setReceipt(withPurchase: purchase, products: [])
        let sut = IAPManager(receiptReader: reader) { purchase in
            if purchase.isUntil(.target) {
                return [.Features.appleTV]
            }
            return []
        }
        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligible(for: .appleTV))
    }
}

// MARK: - Eligibility

extension IAPManagerTests {
    func test_givenPurchasedFeature_whenReloadReceipt_thenIsEligible() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)

        XCTAssertFalse(sut.isEligible(for: ABI.AppFeature.essentialFeatures))

        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.iOS_macOS])
        XCTAssertFalse(sut.isEligible(for: ABI.AppFeature.essentialFeatures))

        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    func test_givenPurchasedFeatures_thenIsOnlyEligibleForFeatures() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [
            .Features.networkSettings
        ])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligible(for: .dns))
        XCTAssertTrue(sut.isEligible(for: .httpProxy))
        XCTAssertFalse(sut.isEligible(for: .onDemand))
        XCTAssertTrue(sut.isEligible(for: .routing))
        XCTAssertFalse(sut.isEligible(for: .sharing))
        XCTAssertFalse(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    func test_givenPurchasedAndCancelledFeature_thenIsNotEligible() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(
            withBuild: defaultBuildNumber,
            products: [.Essentials.iOS_macOS],
            cancelledProducts: [.Essentials.iOS_macOS]
        )
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        XCTAssertFalse(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    func test_givenFreeVersion_thenIsNotEligibleForAnyFeature() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        ABI.AppFeature.essentialFeatures.forEach {
            XCTAssertFalse(sut.isEligible(for: $0))
        }
    }

    func test_givenFreeVersion_thenIsNotEligibleForAppleTV() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        XCTAssertFalse(sut.isEligible(for: .appleTV))
    }

    func test_givenEssentialsVersion_thenIsEligibleForEssentialFeatures() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.iOS_macOS])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        let excluded: Set<ABI.AppFeature> = [
            .appleTV
        ]
        ABI.AppFeature.allCases.forEach {
            if ABI.AppFeature.essentialFeatures.contains($0) {
                XCTAssertTrue(sut.isEligible(for: $0))
                XCTAssertFalse(excluded.contains($0))
            } else {
                XCTAssertFalse(sut.isEligible(for: $0))
                XCTAssertTrue(excluded.contains($0))
            }
        }
    }

    func test_givenAppleTV_thenIsEligibleForAppleTVAndSharing() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Features.appleTV])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligible(for: .appleTV))
        XCTAssertTrue(sut.isEligible(for: .sharing))
    }

    func test_givenPlatformEssentials_thenIsEssentialsForPlatform() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)

#if os(macOS)
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.macOS, .Features.networkSettings])
        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
#else
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.iOS, .Features.networkSettings])
        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
#endif
    }

    func test_givenPlatformEssentials_thenIsNotEssentialsForOtherPlatform() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)

#if os(macOS)
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.iOS, .Features.networkSettings])
        await sut.reloadReceipt()
        XCTAssertFalse(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
#else
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.macOS, .Features.networkSettings])
        await sut.reloadReceipt()
        XCTAssertFalse(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
#endif
    }

    func test_givenUser_thenIsNotEligibleForFeedback() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)
        XCTAssertFalse(sut.isEligibleForFeedback)
    }

    func test_givenBeta_thenIsEligibleForFeedback() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: .max, identifiers: [])
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader)
        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligibleForFeedback)
    }

    func test_givenPayingUser_thenIsEligibleForFeedback() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [.Essentials.iOS])
        let sut = IAPManager(receiptReader: reader)
        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligibleForFeedback)
    }
}

// MARK: - App level

extension IAPManagerTests {
    func test_givenBetaLevel_thenIsRestricted() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader)

        await sut.reloadReceipt()
        XCTAssertTrue(sut.isBeta)
        XCTAssertTrue(sut.userLevel.isBeta)
    }

    func test_givenBetaLevel_thenIsNotEligibleForAllFeatures() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader)

        await sut.reloadReceipt()
        XCTAssertFalse(sut.isEligible(for: ABI.AppFeature.allCases))
    }

    func test_givenBetaLevel_thenIsEligibleForUserLevelFeatures() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader)

        let eligible = ABI.AppUserLevel.beta.features

        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligible(for: eligible))
    }

    func test_givenBetaLevel_thenIsEligibleForUnrestrictedFeature() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader, unrestrictedFeatures: [.onDemand])

        var eligible = ABI.AppUserLevel.beta.features
        eligible.append(.onDemand)

        await sut.reloadReceipt()
        XCTAssertTrue(sut.isEligible(for: eligible))
    }

    func test_givenEssentialsLevel_thenIsEligibleForEssentialFeatures() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(customUserLevel: .essentials, receiptReader: reader)

        await sut.reloadReceipt()
        let excluded: Set<ABI.AppFeature> = [
            .appleTV
        ]
        ABI.AppFeature.allCases.forEach {
            if ABI.AppFeature.essentialFeatures.contains($0) {
                XCTAssertTrue(sut.isEligible(for: $0))
                XCTAssertFalse(excluded.contains($0))
            } else {
                XCTAssertFalse(sut.isEligible(for: $0))
                XCTAssertTrue(excluded.contains($0))
            }
        }
    }

    func test_givenCompleteLevel_thenIsEligibleForAnyFeature() async {
        let reader = FakeAppReceiptReader()
        let sut = IAPManager(customUserLevel: .complete, receiptReader: reader)

        await sut.reloadReceipt()
        ABI.AppFeature.allCases.forEach {
            XCTAssertTrue(sut.isEligible(for: $0))
        }
    }
}

// MARK: - Beta

extension IAPManagerTests {
    func test_givenChecker_whenReloadReceipt_thenIsBeta() async {
        let betaChecker = MockBetaChecker()
        betaChecker.isBeta = true
        let sut = IAPManager(receiptReader: FakeAppReceiptReader(), betaChecker: betaChecker)
        XCTAssertEqual(sut.userLevel, .undefined)
        await sut.reloadReceipt()
        XCTAssertEqual(sut.userLevel, .beta)
    }
}

// MARK: - Receipts

extension IAPManagerTests {
    func test_givenReceipts_whenReloadReceipt_thenPublishesEligibleFeatures() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [
            .Features.appleTV,
            .Features.trustedNetworks
        ])
        let sut = IAPManager(receiptReader: reader)

        let exp = expectation(description: "Eligible features")
        let iapEvents = sut.didChange.subscribe().dropFirst()
        Task {
            for await event in iapEvents {
                switch event {
                case .eligibleFeatures:
                    exp.fulfill()
                default:
                    break
                }
            }
        }

        await sut.reloadReceipt()
        await fulfillment(of: [exp], timeout: CommonLibraryTests.timeout)

        XCTAssertEqual(sut.eligibleFeatures, [
            .appleTV,
            .onDemand,
            .sharing // implied by Apple TV purchase
        ])
    }

    func test_givenInvalidReceipts_whenReloadReceipt_thenSkipsInvalid() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [])
        await reader.addPurchase(with: "foobar")
        await reader.addPurchase(with: .Features.allProviders, expirationDate: Date().addingTimeInterval(-10))
        await reader.addPurchase(with: .Features.appleTV)
        await reader.addPurchase(with: .Features.networkSettings, expirationDate: Date().addingTimeInterval(10))
        await reader.addPurchase(with: .Essentials.iOS, cancellationDate: Date().addingTimeInterval(-60))

        let sut = IAPManager(receiptReader: reader)
        await sut.reloadReceipt()

        XCTAssertEqual(sut.eligibleFeatures, [
            .appleTV,
            .dns,
            .httpProxy,
            .routing,
            .sharing
        ])
    }
}

// MARK: - Observation

extension IAPManagerTests {
    func test_givenManager_whenObserveObjects_thenReloadsReceipt() async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [.Essentials.iOS_macOS])
        let sut = IAPManager(receiptReader: reader)

        XCTAssertEqual(sut.userLevel, .undefined)
        XCTAssertTrue(sut.eligibleFeatures.isEmpty)

        let exp = expectation(description: "Reload receipt")
        let iapEvents = sut.didChange.subscribe().dropFirst()
        Task {
            for await event in iapEvents {
                switch event {
                case .eligibleFeatures:
                    exp.fulfill()
                default:
                    break
                }
            }
        }

        sut.observeObjects()
        await fulfillment(of: [exp], timeout: CommonLibraryTests.timeout)

        XCTAssertNotEqual(sut.userLevel, .undefined)
        XCTAssertFalse(sut.eligibleFeatures.isEmpty)
    }
}

// MARK: -

extension IAPManager {
    convenience init(
        customUserLevel: ABI.AppUserLevel? = nil,
        inAppHelper: (any AppProductHelper)? = nil,
        receiptReader: AppReceiptReader,
        betaChecker: BetaChecker? = nil,
        unrestrictedFeatures: Set<ABI.AppFeature> = [],
        productsAtBuild: BuildProducts<ABI.AppProduct>? = nil
    ) {
        self.init(
            customUserLevel: customUserLevel,
            inAppHelper: inAppHelper ?? FakeAppProductHelper(),
            receiptReader: receiptReader,
            betaChecker: betaChecker ?? TestFlightChecker(),
            unrestrictedFeatures: unrestrictedFeatures,
            timeoutInterval: 5.0,
            verificationDelayMinutesBlock: { _ in 2 },
            productsAtBuild: productsAtBuild
        )
    }

    convenience init(products: Set<ABI.AppProduct>) async {
        let reader = FakeAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: products)
        self.init(receiptReader: reader)
        await reloadReceipt()
    }
}
