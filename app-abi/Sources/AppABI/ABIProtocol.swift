// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C

// FIXME: ###, use typealias for string IDs like ProfileID

public protocol ABIProtocol {
    func initialize(eventContext: UnsafeMutableRawPointer?, eventCallback: psp_event_callback?)

    func profileGetHeaders() -> [ProfileHeaderUI]
    func profileNew() async throws -> ProfileHeaderUI
    func profileImportText(_ text: String) async throws -> ProfileHeaderUI
    func profileUpdate(_ json: String) async throws -> ProfileHeaderUI
    func profileDup(_ id: String) async throws -> ProfileHeaderUI
    func profileDelete(_ id: String) async throws

    func tunnelGetAll() -> [ProfileID: TunnelStatusUI]
    func tunnelSetEnabled(_ enabled: Bool, profileId: String)
}
