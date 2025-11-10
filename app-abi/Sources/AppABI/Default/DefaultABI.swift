// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C
import CommonLibrary

// FIXME: ###, free psp_json after use
final class DefaultABI: ABIProtocol {
    typealias Callback = (Any?, UI.Event) -> Void

    private var eventContext: Any?
    private var eventCallback: Callback?

    // FIXME: ###, business objects, this should map most of AppContext
    private let registry: Registry
    private let profileManager: ProfileManager

    private var profileEventTask: Task<Void, Never>?

    init() {
        registry = Registry()
        profileManager = ProfileManager(profiles: [])
    }

    func initialize(eventContext: Any?, eventCallback: Any?) {
        self.eventContext = eventContext
        self.eventCallback = eventCallback as? Callback
    }

    // MARK: - Profiles

    func profileSave(_ profile: UI.Profile) async throws {
        try await profileManager.save(profile.partoutProfile)
    }

    func profileObserveLocal() async throws {
        try await profileManager.observeLocal()

        profileEventTask = Task { [weak self] in
            guard let self else { return }
            for await event in profileManager.didChange.subscribe() {
                guard !Task.isCancelled else { return }
                dispatch(event)
            }
        }
    }

//    // FIXME: ###, name from args, or from internal constants?
//    func profileNew() async throws -> UI.ProfileHeader {
//        let name = profileManager.firstUniqueName(from: "lorem ipsum")
//        let profile = try Profile.Builder(name: name).build()
//        try await profileManager.save(profile)
//        postArea(PSPAreaProfile)
//        return profile.uiPreview
//    }
//
//    func profileImportText(_ text: String) async throws -> UI.ProfileHeader {
//        let profile = try registry.compatibleProfile(fromString: text)
//        try await profileManager.save(profile)
//        postArea(PSPAreaProfile)
//        return profile.uiPreview
//    }
//
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
#if canImport(Darwin)
    func dispatch(_ event: ProfileManager.Event) {
        switch event {
        case .ready:
            postEvent(.profiles(.ready))
        case .localProfiles(let profiles):
            let object = profiles.reduce(into: [:]) {
                // FIXME: ###, remote flags?
//                $0[$1.key.uuidString] = $1.value.uiHeader(sharingFlags: [])
                $0[$1.key.uuidString] = $1.value.uiProfile
          }
            postEvent(.profiles(.local(object)))
        case .remoteProfiles(let ids):
            let object = Set(ids.map(\.uuidString))
            postEvent(.profiles(.remote(object)))
        case .requiredFeatures(let features):
            let object = features.reduce(into: [:]) {
                $0[$1.key.uuidString] = Set($1.value.map {
                    UI.AppFeature.init(rawValue: $0.rawValue)! // FIXME: ###, dedup AppFeature struct
                })
            }
            postEvent(.profiles(.requiredFeatures(object)))
        default:
            break
        }
    }

    func postEvent(_ event: UI.Event) {
        eventCallback?(eventContext, event)
    }
#else
    // FIXME: ###
    func dispatch(_ event: ProfileManager.Event) {
        switch event {
        case .ready:
            postArea(PSPAreaProfile, PSPEventTypeProfileReady)
//                    isReady = true
        case .localProfiles(let profiles):
            let object = ABIResult(profiles.reduce(into: [:]) {
                // FIXME: ###, remote flags?
//                        $0[$1.key.uuidString] = $1.value.uiHeader(sharingFlags: [])
                $0[$1.key.uuidString] = $1.value.uiProfile
          })
            withUnsafePointer(to: object) {
                self.postArea(PSPAreaProfile, PSPEventTypeProfileLocal, $0)
            }
//                    localProfiles = profiles
        case .remoteProfiles(let ids):
            let object = ABIResult(ids.map(\.uuidString))
            withUnsafePointer(to: object) {
                self.postArea(PSPAreaProfile, PSPEventTypeProfileRemote, $0)
            }
//                    remoteProfileIds = ids
        case .requiredFeatures(let features):
            let object = ABIResult(features)
            withUnsafePointer(to: object) {
                self.postArea(PSPAreaProfile, PSPEventTypeProfileRequiredFeatures, $0)
            }
//                    requiredFeatures = features
        default:
            break
        }
    }

    func postArea(
        _ area: psp_area,
        _ type: psp_event_type = PSPEventTypeNone,
        _ object: UnsafeRawPointer? = nil
    ) {
        eventCallback?(eventContext, psp_event(area: area, type: type, object: object))
    }
#endif
}
