// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
@testable import CommonLibraryCore
import Partout
import Testing

@MainActor
struct IAPManagerTests {
    private let olderBuildNumber = 500

    private let defaultBuildNumber = 1000

    private let newerBuildNumber = 1500
}

extension AppRelease {
    static let target = Self("older", build: 1000)
}

// MARK: - Actions

extension IAPManagerTests {
    @Test
    func givenProducts_whenFetchAppProducts_thenReturnsCorrespondingInAppProducts() async throws {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)

        let appProducts: [ABI.AppProduct] = [
            .Essentials.iOS_macOS,
            .Donations.huge
        ]
        let storeProducts = try await sut.fetchPurchasableProducts(for: appProducts)
        #expect(storeProducts.count == appProducts.count)
        storeProducts.enumerated().forEach { offset, sp in
            let ap = appProducts[offset]
            #expect(sp.product == ap)
            #expect(sp.nativeIdentifier == ap.rawValue)
        }
    }

    @Test
    func givenProducts_whenPurchase_thenIsAddedToPurchasedProducts() async throws {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [])
        let sut = IAPManager(receiptReader: reader)

        let appleTV: ABI.AppProduct = .Features.appleTV
        #expect(!sut.purchasedProducts.contains(appleTV))
        do {
            let purchasable = try await sut.fetchPurchasableProducts(for: [appleTV])
            let purchasableAppleTV = try #require(purchasable.first)
            let result = try await sut.purchase(purchasableAppleTV)
            if result == .done {
                #expect(sut.purchasedProducts.contains(appleTV))
            } else {
                #expect(Bool(false), "Unexpected purchase() result: \(result)")
            }
        } catch {
            #expect(Bool(false), "Unexpected purchase() failure: \(error)")
        }
    }
}

// MARK: - Build products

extension IAPManagerTests {
    @Test
    func givenBuildProducts_whenOlder_thenEssentialsVersion() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: olderBuildNumber, identifiers: [])
        let sut = IAPManager(receiptReader: reader) { [defaultBuildNumber] purchase in
            if purchase.buildNumber <= defaultBuildNumber {
                return [.Essentials.iOS_macOS]
            }
            return []
        }
        await sut.reloadReceipt()
        #expect(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    @Test
    func givenBuildProducts_whenNewer_thenFreeVersion() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: newerBuildNumber, products: [])
        let sut = IAPManager(receiptReader: reader) { [defaultBuildNumber] purchase in
            if purchase.buildNumber <= defaultBuildNumber {
                return [.Essentials.iOS_macOS]
            }
            return []
        }
        await sut.reloadReceipt()
        #expect(!sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    @Test
    func givenBuildProducts_whenFutureRelease_thenFreeVersion() async {
        let reader = FakeInAppReceiptReader()
        let purchase = ABI.OriginalPurchase(buildNumber: .max, purchaseDate: .distantFuture)
        await reader.setReceipt(withPurchase: purchase, products: [])
        let sut = IAPManager(receiptReader: reader) { purchase in
            if purchase.isUntil(.target) {
                return [.Features.appleTV]
            }
            return []
        }
        await sut.reloadReceipt()
        #expect(!sut.isEligible(for: .appleTV))
    }

    @Test
    func givenBuildProducts_whenPastRelease_thenFreeVersion() async {
        let reader = FakeInAppReceiptReader()
        let purchase = ABI.OriginalPurchase(buildNumber: 0, purchaseDate: .distantPast)
        await reader.setReceipt(withPurchase: purchase, products: [])
        let sut = IAPManager(receiptReader: reader) { purchase in
            if purchase.isUntil(.target) {
                return [.Features.appleTV]
            }
            return []
        }
        await sut.reloadReceipt()
        #expect(sut.isEligible(for: .appleTV))
    }
}

// MARK: - Eligibility

extension IAPManagerTests {
    @Test
    func givenPurchasedFeature_whenReloadReceipt_thenIsEligible() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)

        #expect(!sut.isEligible(for: ABI.AppFeature.essentialFeatures))

        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.iOS_macOS])
        #expect(!sut.isEligible(for: ABI.AppFeature.essentialFeatures))

        await sut.reloadReceipt()
        #expect(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    @Test
    func givenPurchasedFeatures_thenIsOnlyEligibleForFeatures() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [
            .Features.networkSettings
        ])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        #expect(sut.isEligible(for: .dns))
        #expect(sut.isEligible(for: .httpProxy))
        #expect(!sut.isEligible(for: .onDemand))
        #expect(sut.isEligible(for: .routing))
        #expect(!sut.isEligible(for: .sharing))
        #expect(!sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    @Test
    func givenPurchasedAndCancelledFeature_thenIsNotEligible() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(
            withBuild: defaultBuildNumber,
            products: [.Essentials.iOS_macOS],
            cancelledProducts: [.Essentials.iOS_macOS]
        )
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        #expect(!sut.isEligible(for: ABI.AppFeature.essentialFeatures))
    }

    @Test
    func givenFreeVersion_thenIsNotEligibleForAnyFeature() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        ABI.AppFeature.essentialFeatures.forEach {
            #expect(!sut.isEligible(for: $0))
        }
    }

    @Test
    func givenFreeVersion_thenIsNotEligibleForAppleTV() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        #expect(!sut.isEligible(for: .appleTV))
    }

    @Test
    func givenEssentialsVersion_thenIsEligibleForEssentialFeatures() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.iOS_macOS])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        let excluded: Set<ABI.AppFeature> = [
            .appleTV
        ]
        ABI.AppFeature.allCases.forEach {
            if ABI.AppFeature.essentialFeatures.contains($0) {
                #expect(sut.isEligible(for: $0))
                #expect(!excluded.contains($0))
            } else {
                #expect(!sut.isEligible(for: $0))
                #expect(excluded.contains($0))
            }
        }
    }

    @Test
    func givenAppleTV_thenIsEligibleForAppleTVAndSharing() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Features.appleTV])
        let sut = IAPManager(receiptReader: reader)

        await sut.reloadReceipt()
        #expect(sut.isEligible(for: .appleTV))
        #expect(sut.isEligible(for: .sharing))
    }

    @Test
    func givenPlatformEssentials_thenIsEssentialsForPlatform() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)

#if os(macOS)
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.macOS, .Features.networkSettings])
        await sut.reloadReceipt()
        #expect(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
#else
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.iOS, .Features.networkSettings])
        await sut.reloadReceipt()
        #expect(sut.isEligible(for: ABI.AppFeature.essentialFeatures))
#endif
    }

    @Test
    func givenPlatformEssentials_thenIsNotEssentialsForOtherPlatform() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)

#if os(macOS)
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.iOS, .Features.networkSettings])
        await sut.reloadReceipt()
        #expect(!sut.isEligible(for: ABI.AppFeature.essentialFeatures))
#else
        await reader.setReceipt(withBuild: defaultBuildNumber, products: [.Essentials.macOS, .Features.networkSettings])
        await sut.reloadReceipt()
        #expect(!sut.isEligible(for: ABI.AppFeature.essentialFeatures))
#endif
    }

    @Test
    func givenUser_thenIsNotEligibleForFeedback() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(receiptReader: reader)
        #expect(!sut.isEligibleForFeedback)
    }

    @Test
    func givenBeta_thenIsEligibleForFeedback() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: .max, identifiers: [])
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader)
        await sut.reloadReceipt()
        #expect(sut.isEligibleForFeedback)
    }

    @Test
    func givenPayingUser_thenIsEligibleForFeedback() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [.Essentials.iOS])
        let sut = IAPManager(receiptReader: reader)
        await sut.reloadReceipt()
        #expect(sut.isEligibleForFeedback)
    }
}

// MARK: - App level

extension IAPManagerTests {
    @Test
    func givenBetaLevel_thenIsRestricted() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader)

        await sut.reloadReceipt()
        #expect(sut.isBeta)
        #expect(sut.userLevel.isBeta)
    }

    @Test
    func givenBetaLevel_thenIsNotEligibleForAllFeatures() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader)

        await sut.reloadReceipt()
        #expect(!sut.isEligible(for: ABI.AppFeature.allCases))
    }

    @Test
    func givenBetaLevel_thenIsEligibleForUserLevelFeatures() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader)

        let eligible = ABI.AppUserLevel.beta.features

        await sut.reloadReceipt()
        #expect(sut.isEligible(for: eligible))
    }

    @Test
    func givenBetaLevel_thenIsEligibleForUnrestrictedFeature() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(customUserLevel: .beta, receiptReader: reader, unrestrictedFeatures: [.onDemand])

        var eligible = ABI.AppUserLevel.beta.features
        eligible.append(.onDemand)

        await sut.reloadReceipt()
        #expect(sut.isEligible(for: eligible))
    }

    @Test
    func givenEssentialsLevel_thenIsEligibleForEssentialFeatures() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(customUserLevel: .essentials, receiptReader: reader)

        await sut.reloadReceipt()
        let excluded: Set<ABI.AppFeature> = [
            .appleTV
        ]
        ABI.AppFeature.allCases.forEach {
            if ABI.AppFeature.essentialFeatures.contains($0) {
                #expect(sut.isEligible(for: $0))
                #expect(!excluded.contains($0))
            } else {
                #expect(!sut.isEligible(for: $0))
                #expect(excluded.contains($0))
            }
        }
    }

    @Test
    func givenCompleteLevel_thenIsEligibleForAnyFeature() async {
        let reader = FakeInAppReceiptReader()
        let sut = IAPManager(customUserLevel: .complete, receiptReader: reader)

        await sut.reloadReceipt()
        ABI.AppFeature.allCases.forEach {
            #expect(sut.isEligible(for: $0))
        }
    }
}

// MARK: - Beta

extension IAPManagerTests {
    @Test
    func givenChecker_whenReloadReceipt_thenIsBeta() async {
        let betaChecker = MockBetaChecker()
        betaChecker.isBeta = true
        let sut = IAPManager(receiptReader: FakeInAppReceiptReader(), betaChecker: betaChecker)
        #expect(sut.userLevel == .undefined)
        await sut.reloadReceipt()
        #expect(sut.userLevel == .beta)
    }
}

// MARK: - Receipts

extension IAPManagerTests {
    @Test
    func givenReceipts_whenReloadReceipt_thenPublishesEligibleFeatures() async throws {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [
            .Features.appleTV,
            .Features.trustedNetworks
        ])
        let sut = IAPManager(receiptReader: reader)

        let exp = Expectation()
        let iapEvents = sut.didChange.subscribe()
        Task {
            for await event in iapEvents {
                switch event {
                case .eligibleFeatures:
                    await exp.fulfill()
                default:
                    break
                }
            }
        }

        await sut.reloadReceipt()
        try await exp.fulfillment(timeout: CommonLibraryTests.timeout)

        #expect(sut.eligibleFeatures == [
            .appleTV,
            .onDemand,
            .sharing // implied by Apple TV purchase
        ])
    }

    @Test
    func givenInvalidReceipts_whenReloadReceipt_thenSkipsInvalid() async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [])
        await reader.addPurchase(with: "foobar")
        await reader.addPurchase(with: .Features.allProviders, expirationDate: Date().addingTimeInterval(-10))
        await reader.addPurchase(with: .Features.appleTV)
        await reader.addPurchase(with: .Features.networkSettings, expirationDate: Date().addingTimeInterval(10))
        await reader.addPurchase(with: .Essentials.iOS, cancellationDate: Date().addingTimeInterval(-60))

        let sut = IAPManager(receiptReader: reader)
        await sut.reloadReceipt()

        #expect(sut.eligibleFeatures == [
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
    @Test
    func givenManager_whenObserveObjects_thenReloadsReceipt() async throws {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: [.Essentials.iOS_macOS])
        let sut = IAPManager(receiptReader: reader)

        #expect(sut.userLevel == .undefined)
        #expect(sut.eligibleFeatures.isEmpty)

        let exp = Expectation()
        let iapEvents = sut.didChange.subscribe()
        Task {
            for await event in iapEvents {
                switch event {
                case .eligibleFeatures:
                    await exp.fulfill()
                default:
                    break
                }
            }
        }

        sut.observeObjects()
        try await exp.fulfillment(timeout: CommonLibraryTests.timeout)

        #expect(sut.userLevel != .undefined)
        #expect(!sut.eligibleFeatures.isEmpty)
    }
}

// MARK: -

extension IAPManager {
    convenience init(
        customUserLevel: ABI.AppUserLevel? = nil,
        inAppHelper: InAppHelper? = nil,
        receiptReader: UserInAppReceiptReader,
        betaChecker: BetaChecker? = nil,
        unrestrictedFeatures: Set<ABI.AppFeature> = [],
        productsAtBuild: BuildProducts? = nil
    ) {
        self.init(
            customUserLevel: customUserLevel,
            inAppHelper: inAppHelper ?? FakeInAppHelper(),
            receiptReader: receiptReader,
            betaChecker: betaChecker ?? MockBetaChecker(),
            unrestrictedFeatures: unrestrictedFeatures,
            timeoutInterval: 5.0,
            verificationDelayMinutesBlock: { _ in 2 },
            productsAtBuild: productsAtBuild
        )
    }

    convenience init(products: Set<ABI.AppProduct>) async {
        let reader = FakeInAppReceiptReader()
        await reader.setReceipt(withBuild: .max, products: products)
        self.init(receiptReader: reader)
        await reloadReceipt()
    }
}
