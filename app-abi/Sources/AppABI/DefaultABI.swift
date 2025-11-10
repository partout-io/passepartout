// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C
import CommonLibrary

// FIXME: ###, free psp_json after use
final class DefaultABI: ABIProtocol {
#if !USE_C_ABI
    typealias Callback = ABICallback
#else
    typealias Callback = ABICCallback
#endif

    private var eventContext: UnsafeRawPointer?
    private var eventCallback: Callback?

    // FIXME: ###, business objects, this should map most of AppContext
    private let registry: Registry
    private let profileManager: ProfileManager

    private var profileEventTask: Task<Void, Never>?

    init() {
        registry = Registry()
        profileManager = ProfileManager(profiles: [])
    }

    func initialize(eventContext: UnsafeRawPointer?, eventCallback: Callback?) {
        self.eventContext = eventContext
        self.eventCallback = eventCallback
    }

    // MARK: - Profiles

    func profileObserve() async throws {
        try await profileManager.observeLocal()
        try await profileManager.observeRemote(repository: InMemoryProfileRepository())

        profileEventTask = Task { [weak self] in
            guard let self else { return }
            for await event in profileManager.didChange.subscribe() {
                guard !Task.isCancelled else { return }
                dispatch(event)
            }
        }
    }

    // FIXME: ###, .partoutProfile mapping is bs
    func profileSave(_ profile: UI.Profile) async throws {
        try await profileManager.save(profile.partoutProfile)
    }

    // FIXME: ###, name from args, or from internal constants?
    func profileNew(named name: String) async throws {
        let profile = try Profile.Builder(name: name).build()
        try await profileManager.save(profile)
    }

    func profileImportText(_ text: String) async throws {
        let profile = try registry.compatibleProfile(fromString: text)
        try await profileManager.save(profile, remotelyShared: true)
    }

//    func profileUpdate(_ json: String) async throws -> UI.ProfileHeader {
//        // FIXME: ###
//        postArea(PSPAreaProfile)
//        fatalError()
//    }
//
//    func profileDup(_ id: String) async throws -> UI.ProfileHeader {
//        // FIXME: ###
//        postArea(PSPAreaProfile)
//        fatalError()
//    }
//
//    func profileDelete(_ id: String) async throws {
//        // FIXME: ###
//        postArea(PSPAreaProfile)
//        fatalError()
//    }

//    // MARK: - Tunnel
//
//    func tunnelGetAll() -> [ProfileID : UI.TunnelStatus] {
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

    func postEvent(_ event: UI.Event) {
#if !USE_C_ABI
        eventCallback?(eventContext, event)
#else
        eventCallback?(eventContext, event.pspEvent)
#endif
    }
}

//extension UI.Event {
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
