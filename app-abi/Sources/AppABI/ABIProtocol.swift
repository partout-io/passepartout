// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C

// FIXME: ###, use typealias for string IDs like ProfileID

public protocol ABIProtocol {
    func initialize(eventContext: UnsafeRawPointer?, eventCallback: Any?)

    func profileSave(_ profile: UI.Profile) async throws
//    func profileNew() async throws -> UI.ProfileHeader
//    func profileImportText(_ text: String) async throws -> UI.ProfileHeader
//    func profileUpdate(_ json: String) async throws -> UI.ProfileHeader
//    func profileDup(_ id: UI.Identifier) async throws -> UI.ProfileHeader
//    func profileDelete(_ id: UI.Identifier) async throws
//    func profileSave(_ json: String) async throws
    func profileObserveLocal() async throws
//
//    func tunnelGetAll() -> [UI.Identifier: UI.TunnelStatus]
//    func tunnelSetEnabled(_ enabled: Bool, profileId: UI.Identifier)
}

#if canImport(Darwin)
extension UI {
    public enum Event {
        case profiles(ProfileEvent)
        case tunnel
    }

    public enum ProfileEvent {
        case ready
        case local([Identifier: Profile])
        case remote(Set<Identifier>)
        case requiredFeatures([Identifier: Set<AppFeature>])
    }
}

@MainActor
public protocol ABIObserver {
    func onUpdate(_ event: UI.Event)
}
#else
@MainActor
public protocol ABIObserver {
    func onUpdate(_ event: psp_event)
}

public final class ABIResult {
    public let value: Any

    init(_ value: Any) {
        self.value = value
    }
}
#endif
