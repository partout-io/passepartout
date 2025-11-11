// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonABI_C

// FIXME: ###, use typealias for string IDs like ProfileID

public protocol ABIProtocol {
#if !USE_C_ABI
    typealias EventCallback = ABIEventCallback
#else
    typealias EventCallback = ABICEventCallback
#endif

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

public typealias ABIEventCallback = (UnsafeRawPointer?, ABI.Event) -> Void
public typealias ABIEventCCallback = (UnsafeRawPointer?, psp_event) -> Void

@MainActor
public protocol ABIObserver {
#if !USE_C_ABI
    func onUpdate(_ event: ABI.Event)
#else
    func onUpdate(_ event: psp_event)
#endif
}
