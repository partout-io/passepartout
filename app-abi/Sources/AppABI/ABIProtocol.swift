// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C

// FIXME: ###, use typealias for string IDs like ProfileID

public protocol ABIProtocol {
    func initialize(eventContext: UnsafeMutableRawPointer?, eventCallback: psp_event_callback?)

    func profileGetHeaders() -> [UI.ProfileHeader]
    func profileNew() async throws -> UI.ProfileHeader
    func profileImportText(_ text: String) async throws -> UI.ProfileHeader
    func profileUpdate(_ json: String) async throws -> UI.ProfileHeader
    func profileDup(_ id: String) async throws -> UI.ProfileHeader
    func profileDelete(_ id: String) async throws

    func tunnelGetAll() -> [ProfileID: UI.TunnelStatus]
    func tunnelSetEnabled(_ enabled: Bool, profileId: String)
}
