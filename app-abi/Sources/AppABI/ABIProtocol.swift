// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUI

// FIXME: ###, use typealias for string IDs like ProfileID

public protocol ABIProtocol {
    func initialize(eventContext: UnsafeRawPointer?, eventCallback: ABICallback?)

    func profileObserve() async throws
    func profileSave(_ profile: UI.Profile) async throws
    func profileNew(named name: String) async throws
    func profileImportText(_ text: String) async throws
//    func profileUpdate(_ json: String) async throws -> UI.ProfileHeader
//    func profileDup(_ id: UI.Identifier) async throws -> UI.ProfileHeader
//    func profileDelete(_ id: UI.Identifier) async throws
//    func profileSave(_ json: String) async throws
//
//    func tunnelGetAll() -> [UI.Identifier: UI.TunnelStatus]
//    func tunnelSetEnabled(_ enabled: Bool, profileId: UI.Identifier)
}

public typealias ABICallback = (UnsafeRawPointer?, UI.Event) -> Void

#if canImport(Darwin)
@MainActor
public protocol ABIObserver {
    func onUpdate(_ event: UI.Event)
}
#else
@MainActor
public protocol ABIObserver {
    func onUpdate(_ event: psp_event)
}

@MainActor
public final class ABIResult {
    public let value: Any

    init(_ value: Any) {
        self.value = value
    }
}
#endif
