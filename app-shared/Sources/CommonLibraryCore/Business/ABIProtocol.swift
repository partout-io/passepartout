// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore_C

// FIXME: #1594, use typealias for string IDs like ProfileID

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

@MainActor
public protocol ABIProtocol {
    // MARK: Global
    var appConfiguration: ABI.AppConfiguration { get }
    var logger: AppLogger { get }

    // MARK: Events
    typealias EventCallback = @Sendable (ABIEventContext?, ABICallbackEvent) -> Void
    func registerEvents(context: ABIEventContext?, callback: @escaping EventCallback)

    // MARK: Lifecycle
    func onApplicationActive()

    // MARK: Config
    func configRefreshBundle() async
    func configIsActive(_ flag: ABI.ConfigFlag) -> Bool
    func configData(for flag: ABI.ConfigFlag) -> JSON?
    var configActiveFlags: Set<ABI.ConfigFlag> { get }

    // MARK: Encoder
    func encoderDefaultFilename(for profile: ABI.AppProfile) -> String
    func encoderProfile(fromString string: String) throws -> ABI.AppProfile
    func encoderJSON(fromProfile profile: ABI.AppProfile) throws -> String
    func encoderWriteToFile(_ profile: ABI.AppProfile) throws -> String

    // MARK: IAP
    func iapVerify(_ profile: ABI.AppProfile) throws
    var iapIsBeta: Bool { get }
    var iapVerificationDelayMinutes: Int { get }

    // MARK: Profile
    func profile(withId id: ABI.AppIdentifier) -> ABI.AppProfile?
    func profileNew(named name: String) async throws
    func profileSave(_ profile: ABI.AppProfile, sharing: ABI.ProfileSharingFlag) async throws
    func profileImportText(_ text: String, filename: String, passphrase: String?) async throws
    func profileImportFile(_ path: String, passphrase: String?) async throws
    func profileDup(_ id: ABI.AppIdentifier) async throws
    func profileRemove(_ id: ABI.AppIdentifier) async
    func profileRemove(_ ids: [ABI.AppIdentifier]) async
    func profileRemoveAllRemote() async throws

    // MARK: Tunnel
    func tunnelConnect(to profile: ABI.AppProfile, force: Bool) async throws
//    func tunnelReconnect(to profileId: ABI.AppIdentifier) async throws
    func tunnelDisconnect(from profileId: ABI.AppIdentifier) async throws
    func tunnelCurrentLog() async -> [ABI.AppLogLine]
    func tunnelLastError(ofProfileId profileId: ABI.AppIdentifier) -> ABI.AppError?
    func tunnelTransfer(ofProfileId profileId: ABI.AppIdentifier) -> ABI.ProfileTransfer?

    // MARK: Version
    func versionCheckLatestRelease() async
    var versionLatestRelease: ABI.VersionRelease? { get }

    // MARK: Web receiver
    func webReceiverStart() throws
    func webReceiverStop()
    func webReceiverRefresh()
    var webReceiverIsStarted: Bool { get }
    var webReceiverWebsite: ABI.WebsiteWithPasscode? { get }

    // FIXME: #1594, Drop these, expose actions via ABI
    var appEncoder: AppEncoder { get }
    var configManager: ConfigManager { get }
    var iapManager: IAPManager { get }
    var kvManager: KeyValueManager { get }
    var profileManager: ProfileManager { get }
    var registry: Registry { get }
    var tunnel: ExtendedTunnel { get }
    var versionChecker: VersionChecker { get }
    var webReceiverManager: WebReceiverManager { get }
    // Legacy
    var apiManager: APIManager { get }
    var preferencesManager: PreferencesManager { get }
}

extension ABIProtocol {
    public func tunnelConnect(to profileId: ABI.AppIdentifier, force: Bool) async throws {
        guard let profile = profileManager.partoutProfile(withId: profileId) else {
            throw ABI.AppError.notFound
        }
        try await tunnelConnect(to: ABI.AppProfile(native: profile), force: force)
    }
}
