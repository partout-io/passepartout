// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonABI_C

// FIXME: ###, use typealias for string IDs like ProfileID

public protocol ABIProtocol {
#if !USE_C_ABI
    func initialize(eventContext: UnsafeRawPointer?, eventCallback: ABIEventCallback?)
#else
    func initialize(eventContext: UnsafeRawPointer?, eventCallback: ABIEventCCallback?)
#endif

    func profileObserve() async throws
    func profileSave(_ profile: ABI.Profile) async throws
    func profileNew(named name: String) async throws
    func profileImportText(_ text: String) async throws
//    func profileUpdate(_ json: String) async throws -> ABI.ProfileHeader
//    func profileDup(_ id: ABI.Identifier) async throws -> ABI.ProfileHeader
//    func profileDelete(_ id: ABI.Identifier) async throws
//    func profileSave(_ json: String) async throws
//
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
