// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C

// FIXME: ###, free psp_json after use
final class MockABI: ABIProtocol {
    private var eventContext: UnsafeMutableRawPointer?
    private var eventCallback: psp_event_callback?

    private var profiles: [UI.ProfileHeader] {
        didSet {
            profiles.sort()
        }
    }

    private var statuses: [UI.Identifier: UI.TunnelStatus]

    init() {
        profiles = [
            UI.ProfileHeader(id: "1", name: "foo"),
            UI.ProfileHeader(id: "2", name: "bar"),
            UI.ProfileHeader(id: "3", name: "sum")
        ]
        profiles.sort()
        statuses = [:]
    }

    func initialize(eventContext: UnsafeMutableRawPointer?, eventCallback: psp_event_callback?) {
        self.eventContext = eventContext
        self.eventCallback = eventCallback
    }

    // MARK: - Profiles

    func profileGetHeaders() -> [UI.ProfileHeader] {
        profiles
    }

    func profileNew() async throws -> UI.ProfileHeader {
        let dto = UI.ProfileHeader(id: "lorem-ipsum", name: "lorem ipsum")
        profiles.append(dto)
        postArea(PSPAreaProfile)
        return dto
    }

    func profileImportText(_ text: String) async throws -> UI.ProfileHeader {
        // FIXME: ###, do not parse as DTO, parse with Registry
        let dto = try UI.ProfileHeader(json: text)
        profiles.append(dto)
        postArea(PSPAreaProfile)
        return dto
    }

    func profileUpdate(_ json: String) async throws -> UI.ProfileHeader {
        // FIXME: ###
        postArea(PSPAreaProfile)
        fatalError()
    }

    func profileDup(_ id: UI.Identifier) async throws -> UI.ProfileHeader {
        // FIXME: ###
        postArea(PSPAreaProfile)
        fatalError()
    }

    func profileDelete(_ id: UI.Identifier) async throws {
        // FIXME: ###
        postArea(PSPAreaProfile)
        fatalError()
    }

    // MARK: - Tunnel

    func tunnelGetAll() -> [UI.Identifier: UI.TunnelStatus] {
        statuses
    }

    func tunnelSetEnabled(_ enabled: Bool, profileId: String) {
        statuses[profileId] = enabled ? .connected : .disconnected
        postArea(PSPAreaTunnel)
    }
}

private extension MockABI {
    func postArea(_ area: psp_area) {
        eventCallback?(eventContext, psp_event(area: area))
    }
}
