// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore_C

// MARK: Domains

@MainActor
public protocol AppABIConfigProtocol: Sendable {
    var configActiveFlags: Set<ABI.ConfigFlag> { get }
    func configData(for flag: ABI.ConfigFlag) -> JSON?
}

@MainActor
public protocol AppABIEncoderProtocol: Sendable {
    func encoderDefaultFilename(for profile: ABI.AppProfile) -> String
    func encoderProfile(fromString string: String) throws -> ABI.AppProfile
    func encoderJSON(fromProfile profile: ABI.AppProfile) throws -> String
    func encoderWriteToFile(_ profile: ABI.AppProfile) throws -> String
}

@MainActor
public protocol AppABIIAPProtocol: Sendable {
    func iapIsEnabled() -> Bool
    func iapEnable(_ isEnabled: Bool)
    func iapVerify(_ profile: ABI.AppProfile, extra: Set<ABI.AppFeature>?) throws
    var iapPurchasedProducts: Set<ABI.AppProduct> { get }
    var iapIsBeta: Bool { get }
    func iapIsEligible(for feature: ABI.AppFeature) -> Bool
    var iapIsEligibleForFeedback: Bool { get }
    var iapVerificationDelayMinutes: Int { get }
}

@MainActor
public protocol AppABIProfileProtocol: Sendable {
    func profile(withId id: ABI.AppIdentifier) -> ABI.AppProfile?
    func profileSave(_ profile: ABI.AppProfile, remotelyShared: Bool?) async throws
    func profileSaveAll() async
    func profileImportText(_ text: String, filename: String, passphrase: String?) async throws
    func profileImportFile(_ path: String, passphrase: String?) async throws
    func profileDup(_ id: ABI.AppIdentifier) async throws
    func profileRemove(_ id: ABI.AppIdentifier) async
    func profileRemove(_ ids: [ABI.AppIdentifier]) async
    func profileRemoveAllRemote() async throws
    func profileIsRemotelyShared(_ id: ABI.AppIdentifier) -> Bool
}

@MainActor
public protocol AppABIRegistryProtocol: Sendable {
    func registryNewModule(ofType type: ModuleType) -> any ModuleBuilder
    func registryValidate(_ builder: any ModuleBuilder) throws
    func registryImplementation(for id: ModuleHandler.ID) -> ModuleImplementation?
    func registryResolvedModule(_ module: ProviderModule) throws -> Module
    func registryImportedProfile(from input: ABI.ProfileImporterInput, passphrase: String?) throws -> Profile
}

@MainActor
public protocol AppABITunnelProtocol: Sendable {
    func tunnelConnect(to profile: ABI.AppProfile, force: Bool) async throws
//    func tunnelReconnect(to profileId: ABI.AppIdentifier) async throws
    func tunnelDisconnect(from profileId: ABI.AppIdentifier) async throws
    func tunnelCurrentLog() async -> [ABI.AppLogLine]
    func tunnelLastError(ofProfileId profileId: ABI.AppIdentifier) -> ABI.AppError?
    func tunnelTransfer(ofProfileId profileId: ABI.AppIdentifier) -> ABI.ProfileTransfer?
}

@MainActor
public protocol AppABIVersionProtocol: Sendable {
    func versionCheckLatestRelease() async
    var versionLatestRelease: ABI.VersionRelease? { get }
}

@MainActor
public protocol AppABIWebReceiverProtocol: Sendable {
    func webReceiverStart() throws
    func webReceiverStop()
    func webReceiverRefresh()
    var webReceiverIsStarted: Bool { get }
    var webReceiverWebsite: ABI.WebsiteWithPasscode? { get }
}

// MARK: - Aggregate

#if !PSP_CROSS
public typealias ABICallbackEvent = ABI.Event
#else
public typealias ABICallbackEvent = UnsafePointer<psp_event>
#endif

public struct ABIEventContext: @unchecked Sendable {
    public let pointer: UnsafeRawPointer
    public init(pointer: UnsafeRawPointer) {
        self.pointer = pointer
    }
}

extension AppABITunnelProtocol where Self: AppABIProfileProtocol {
    public func tunnelConnect(to profileId: ABI.AppIdentifier, force: Bool) async throws {
        guard let profile = profile(withId: profileId) else {
            throw ABI.AppError.notFound
        }
        try await tunnelConnect(to: profile, force: force)
    }
}
