// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore_C
// FIXME: #1594, Drop import (Module*)
import Partout

// MARK: Domains

@MainActor
public protocol AppABIConfigProtocol: Sendable {
    var activeFlags: Set<ABI.ConfigFlag> { get }
    func data(for flag: ABI.ConfigFlag) -> JSON?
}

@MainActor
public protocol AppABIEncoderProtocol: Sendable {
    func defaultFilename(for profile: ABI.AppProfile) -> String
    func profile(fromString string: String) throws -> ABI.AppProfile
    func json(fromProfile profile: ABI.AppProfile) throws -> String
    func writeToFile(_ profile: ABI.AppProfile) throws -> String
}

@MainActor
public protocol AppABIIAPProtocol: Sendable {
    var isEnabled: Bool { get }
    func enable(_ isEnabled: Bool)
    func purchase(_ storeProduct: ABI.StoreProduct) async throws -> ABI.StoreResult
    func verify(_ profile: ABI.AppProfile, extra: Set<ABI.AppFeature>?) throws
    func reloadReceipt() async
    func restorePurchases() async throws
    func suggestedProducts(for features: Set<ABI.AppFeature>) -> Set<ABI.AppProduct>
    func purchasableProducts(for products: [ABI.AppProduct]) async throws -> [ABI.StoreProduct]
    var originalPurchase: ABI.OriginalPurchase? { get }
    var purchasedProducts: Set<ABI.AppProduct> { get }
    var isBeta: Bool { get }
    func isEligible(for feature: ABI.AppFeature) -> Bool
    func isEligible(for features: Set<ABI.AppFeature>) -> Bool
    var isEligibleForFeedback: Bool { get }
    var isEligibleForComplete: Bool { get }
    var verificationDelayMinutes: Int { get }
}

@MainActor
public protocol AppABIProfileProtocol: Sendable {
    func profile(withId id: ABI.AppIdentifier) -> ABI.AppProfile?
    func save(_ profile: ABI.AppProfile, remotelyShared: Bool?) async throws
    func saveAll() async
    func importText(_ text: String, filename: String, passphrase: String?) async throws
    func importFile(_ path: String, passphrase: String?) async throws
    func duplicate(_ id: ABI.AppIdentifier) async throws
    func remove(_ id: ABI.AppIdentifier) async
    func remove(_ ids: [ABI.AppIdentifier]) async
    func removeAllRemote() async throws
    func isRemotelyShared(_ id: ABI.AppIdentifier) -> Bool
    var isRemoteImportingEnabled: Bool { get }
}

@MainActor
public protocol AppABIRegistryProtocol: Sendable {
    func newModule(ofType type: ModuleType) -> any ModuleBuilder
    func validate(_ builder: any ModuleBuilder) throws
    func implementation(for id: ModuleHandler.ID) -> ModuleImplementation?
    func resolvedModule(_ module: ProviderModule) throws -> Module
}

public enum AppABITunnelValueKey: Sendable {
    case openVPNServerConfiguration
}

@MainActor
public protocol AppABITunnelProtocol: Sendable {
    func connect(to profile: ABI.AppProfile, force: Bool) async throws
//    func reconnect(to profileId: ABI.AppIdentifier) async throws
    func disconnect(from profileId: ABI.AppIdentifier) async throws
    func currentLog() async -> [ABI.AppLogLine]
    func lastError(ofProfileId profileId: ABI.AppIdentifier) -> ABI.AppError?
    func transfer(ofProfileId profileId: ABI.AppIdentifier) -> ABI.ProfileTransfer?
    func environmentValue(for key: AppABITunnelValueKey, ofProfileId profileId: ABI.AppIdentifier) -> Any?
}

@MainActor
public protocol AppABIVersionProtocol: Sendable {
    func checkLatestRelease() async
    var latestRelease: ABI.VersionRelease? { get }
}

@MainActor
public protocol AppABIWebReceiverProtocol: Sendable {
    func start() throws
    func stop()
    func refresh()
    var isStarted: Bool { get }
    var website: ABI.WebsiteWithPasscode? { get }
}

// MARK: - Aggregate

extension AppABITunnelProtocol where Self: AppABIProfileProtocol {
    public func connect(to profileId: ABI.AppIdentifier, force: Bool) async throws {
        guard let profile = profile(withId: profileId) else {
            throw ABI.AppError.notFound
        }
        try await connect(to: profile, force: force)
    }
}
