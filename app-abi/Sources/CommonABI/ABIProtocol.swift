// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonABI_C

// FIXME: ###, use typealias for string IDs like ProfileID

#if !USE_C_ABI
public typealias ABICallbackEvent = ABI.Event
#else
public typealias ABICallbackEvent = psp_event
#endif

public protocol ABIProtocol {
    typealias EventCallback = (UnsafeRawPointer?, ABICallbackEvent) -> Void

    func registerEvents(context: UnsafeRawPointer?, callback: EventCallback?)

//    func profile(withId id: ABI.Identifier) async -> ABI.Profile?
    func profileSave(_ profile: ABI.Profile) async throws
    func profileNew(named name: String) async throws
    func profileImportText(_ text: String) async throws
//    func profileDup(_ id: ABI.Identifier) async throws -> ABI.ProfileHeader
    func profileDelete(_ id: ABI.Identifier) async

//    func tunnelGetAll() -> [ABI.Identifier: ABI.TunnelStatus]
//    func tunnelSetEnabled(_ enabled: Bool, profileId: ABI.Identifier)
}

@MainActor
public protocol ABIObserver {
    func onUpdate(_ event: ABICallbackEvent)
}
