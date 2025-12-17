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
    typealias EventCallback = @Sendable (ABIEventContext?, ABICallbackEvent) -> Void
    func registerEvents(context: ABIEventContext?, callback: @escaping EventCallback)
    func onApplicationActive()

    // FIXME: #1594, Implement ABI actions
//    func profile(withId id: ABI.AppIdentifier) async -> ABI.AppProfile?
//    func profileSave(_ profile: ABI.AppProfile) async throws
//    func profileNew(named name: String) async throws
//    func profileDup(_ id: ABI.AppIdentifier) async throws
//    func profileImportText(_ text: String) async throws
//    func profileRemove(_ id: ABI.AppIdentifier) async
//    func profileRemove(_ ids: [ABI.AppIdentifier]) async
//    func profileRemoveAllRemote() async throws
//
//    func tunnelConnect(to profileId: ABI.AppIdentifier, force: Bool) async throws
////    func tunnelReconnect(to profileId: ABI.AppIdentifier) async throws
//    func tunnelDisconnect(from profileId: ABI.AppIdentifier) async throws
//    func tunnelCurrentLog() async -> [String]

    // FIXME: #1594, Deprecate, make internal
    var appConfiguration: ABI.AppConfiguration { get }
    var apiManager: APIManager { get }
    var appEncoder: AppEncoder { get }
    var configManager: ConfigManager { get }
    var iapManager: IAPManager { get }
    var kvManager: KeyValueManager { get }
    var logger: AppLogger { get }
    var preferencesManager: PreferencesManager { get }
    var profileManager: ProfileManager { get }
    var registry: Registry { get }
    var tunnel: ExtendedTunnel { get }
    var versionChecker: VersionChecker { get }
    var webReceiverManager: WebReceiverManager { get }
}
