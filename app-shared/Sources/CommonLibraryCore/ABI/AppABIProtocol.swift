// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore_C
import Partout

// MARK: Domains

public protocol AppABIEncoderProtocol: Sendable {
    nonisolated func defaultFilename(for profileName: String) -> String
    nonisolated func profile(fromString string: String) throws -> Profile
    nonisolated func json(fromProfile profile: Profile) throws -> String
    nonisolated func writeToFile(_ profile: Profile) throws -> String
}

@MainActor
public protocol AppABIIAPProtocol: Sendable {
    func enable(_ isEnabled: Bool)
    func purchase(_ storeProduct: ABI.StoreProduct) async throws -> ABI.StoreResult
    func verify(_ profile: Profile, extra: Set<ABI.AppFeature>?) throws
    func reloadReceipt() async
    func restorePurchases() async throws
    func suggestedProducts(for features: Set<ABI.AppFeature>, hints: Set<ABI.StoreProductHint>?) -> Set<ABI.AppProduct>
    func purchasableProducts(for products: [ABI.AppProduct]) async throws -> [ABI.StoreProduct]
    var verificationDelayMinutes: Int { get }
}

@MainActor
public protocol AppABILoggerProtocol: Sendable {
    func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String)
    func flushLogs()
}

@MainActor
public protocol AppABIProfileProtocol: Sendable {
    func profile(withId id: Profile.ID) -> Profile?
    func save(_ profile: Profile, remotelyShared: Bool?) async throws
    func saveAll() async
    func importText(_ text: String, filename: String, passphrase: String?) async throws
    func importFile(_ path: String, passphrase: String?) async throws
    func duplicate(_ id: Profile.ID) async throws
    func remove(_ id: Profile.ID) async
    func remove(_ ids: [Profile.ID]) async
    func removeAllRemote() async throws
}

@MainActor
public protocol AppABIRegistryProtocol: Sendable {
    func importedProfile(from input: ABI.ProfileImporterInput) throws -> Profile
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
    func connect(to profile: Profile, force: Bool) async throws
//    func reconnect(to profileId: Profile.ID) async throws
    func disconnect(from profileId: Profile.ID) async throws
    func currentLog() async -> [ABI.AppLogLine]
    // These are non-observable (pull manually)
    func lastError(ofProfileId profileId: Profile.ID) -> ABI.AppError?
    func transfer(ofProfileId profileId: Profile.ID) -> ABI.ProfileTransfer?
    func environmentValue(for key: AppABITunnelValueKey, ofProfileId profileId: Profile.ID) -> Any?
}

@MainActor
public protocol AppABIVersionProtocol: Sendable {
    func checkLatestRelease() async
}

@MainActor
public protocol AppABIWebReceiverProtocol: Sendable {
    func start() throws
    func stop()
}

// MARK: - Aggregate

extension AppABITunnelProtocol where Self: AppABIProfileProtocol {
    public func connect(to profileId: Profile.ID, force: Bool) async throws {
        guard let profile = profile(withId: profileId) else {
            throw ABI.AppError.notFound
        }
        try await connect(to: profile, force: force)
    }
}
