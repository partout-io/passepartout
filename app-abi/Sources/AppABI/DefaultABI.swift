// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonABI_C
import CommonABI
import CommonLibrary

extension ABI {
    public static var `default`: ABIProtocol {
        DefaultABI()
    }
}

// FIXME: ###, free psp_json after use
final class DefaultABI: ABIProtocol {
    private var eventContext: UnsafeRawPointer?
    private var eventCallback: EventCallback?

    // FIXME: ###, business objects, this should map most of AppContext
    private let registry: Registry
    private let profileManager: ProfileManager

    private var profileEventTask: Task<Void, Never>?

    init() {
        registry = Registry()
        profileManager = ProfileManager(profiles: [])
    }

    func registerEvents(context: UnsafeRawPointer?, callback: EventCallback?) {
        eventContext = context
        eventCallback = callback

        Task {
            // FIXME: ###, this is not so easy, done on app launch/foreground with IAP updates
            try await profileManager.observeLocal()
            try await profileManager.observeRemote(repository: InMemoryProfileRepository())
        }
        profileEventTask = Task { [weak self] in
            guard let self else { return }
            for await event in profileManager.didChange.subscribe() {
                guard !Task.isCancelled else { return }
                dispatch(event)
            }
        }
    }

    // MARK: - Profiles

    func profile(withId id: ABI.Identifier) async -> ABI.Profile? {
        guard let profileId = UUID(uuidString: id) else {
            preconditionFailure()
        }
        return await profileManager.profile(withId: profileId)
    }

    func profileSave(_ profile: ABI.Profile) async throws {
        let partoutProfile = try profile.partoutProfile()
        try await profileManager.save(partoutProfile)
    }

    func profileNew(named name: String) async throws {
        try await profileManager.new(named: name)
    }

    func profileDup(_ id: ABI.Identifier) async throws {
        guard let profileId = UUID(uuidString: id) else {
            preconditionFailure()
        }
        try await profileManager.duplicate(profileWithId: profileId)
    }

    func profileImportText(_ text: String) async throws {
        var profile = try registry.compatibleProfile(fromString: text)
        // FIXME: ###, faking shared
        var builder = profile.builder()
        builder.attributes.isAvailableForTV = .random()
        profile = try builder.build()
        try await profileManager.save(profile, remotelyShared: true)
    }

    func profileRemove(_ id: ABI.Identifier) async {
        guard let profileId = UUID(uuidString: id) else {
            preconditionFailure()
        }
        await profileManager.remove(withId: profileId)
    }

    func profileRemove(_ ids: [ABI.Identifier]) async {
        let profileIds = ids.map {
            guard let profileId = UUID(uuidString: $0) else {
                preconditionFailure()
            }
            return profileId
        }
        await profileManager.remove(withIds: profileIds)
    }

    func profileRemoveAllRemote() async throws {
        try await profileManager.eraseRemotelySharedProfiles()
    }

//    // MARK: - Tunnel
//
//    func tunnelGetAll() -> [ProfileID : ABI.TunnelStatus] {
//        // FIXME: ###
//        [:]
//    }
//
//    func tunnelSetEnabled(_ enabled: Bool, profileId: String) {
////        let dtoId = String(cString: profileId)
////        statuses[dtoId] = enabled ? .connected : .disconnected
//        postArea(PSPAreaTunnel)
//    }
}

// MARK: - Events

private extension DefaultABI {
    func dispatch(_ event: ProfileManager.Event) {
        switch event {
        case .ready:
            postEvent(.profiles(.ready))
        case .refresh(let headers):
            postEvent(.profiles(.refresh(headers)))
        default:
            break
        }
    }

    func postEvent(_ event: ABI.Event) {
#if !USE_C_ABI
        eventCallback?(eventContext, event)
#else
        eventCallback?(eventContext, event.pspEvent)
#endif
    }
}

//extension ABI.Event {
//    // FIXME: ###
//    var pspEvent: psp_event {
//        switch self {
//        case .ready:
//            postArea(PSPAreaProfile, PSPEventTypeProfileReady)
////                    isReady = true
//        case .refresh(let profiles):
//            let object = ABIResult(profiles.reduce(into: [:]) {
//                // FIXME: ###, remote flags?
////                        $0[$1.key.uuidString] = $1.value.uiHeader(sharingFlags: [])
//                $0[$1.key.uuidString] = $1.value.uiProfile
//          })
//            withUnsafePointer(to: object) {
//                self.postArea(PSPAreaProfile, PSPEventTypeProfileLocal, $0)
//            }
////                    localProfiles = profiles
//        case .remoteProfiles(let ids):
//            let object = ABIResult(ids.map(\.uuidString))
//            withUnsafePointer(to: object) {
//                self.postArea(PSPAreaProfile, PSPEventTypeProfileRemote, $0)
//            }
////                    remoteProfileIds = ids
//        case .requiredFeatures(let features):
//            let object = ABIResult(features)
//            withUnsafePointer(to: object) {
//                self.postArea(PSPAreaProfile, PSPEventTypeProfileRequiredFeatures, $0)
//            }
////                    requiredFeatures = features
//        default:
//            break
//        }
//    }
//}
