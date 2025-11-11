// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C
import CommonABI

// FIXME: ###, use typealias for string IDs like ProfileID

public protocol ABIProtocol {
#if !USE_C_ABI
    func initialize(eventContext: UnsafeRawPointer?, eventCallback: ABICallback?)
#else
    func initialize(eventContext: UnsafeRawPointer?, eventCallback: ABICCallback?)
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

public typealias ABICallback = (UnsafeRawPointer?, ABI.Event) -> Void
public typealias ABICCallback = (UnsafeRawPointer?, psp_event) -> Void

#if !USE_C_ABI
@MainActor
public protocol ABIObserver {
    func onUpdate(_ event: ABI.Event)
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
