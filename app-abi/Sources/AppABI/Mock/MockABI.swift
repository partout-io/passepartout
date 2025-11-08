// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C

// FIXME: ###, free psp_json after use
final class MockABI: ABIProtocol {
    private var eventContext: UnsafeMutableRawPointer?
    private var eventCallback: psp_event_callback?

    private var profiles: [ProfileHeaderUI] {
        didSet {
            profiles.sort()
        }
    }

    private var statuses: [ProfileID: TunnelStatusUI]

    init() {
        profiles = [
            ProfileHeaderUI(id: "1", name: "foo"),
            ProfileHeaderUI(id: "2", name: "bar"),
            ProfileHeaderUI(id: "3", name: "sum")
        ]
        profiles.sort()
        statuses = [:]
    }

    func initialize(eventContext: UnsafeMutableRawPointer?, eventCallback: psp_event_callback?) {
        self.eventContext = eventContext
        self.eventCallback = eventCallback
    }

    // MARK: - Profiles

    func profileGetHeaders() -> [ProfileHeaderUI] {
        profiles
    }

    func profileNew() async throws -> ProfileHeaderUI {
        let dto = ProfileHeaderUI(id: "lorem-ipsum", name: "lorem ipsum")
        profiles.append(dto)
        postArea(PSPAreaProfile)
        return dto
    }

    func profileImportText(_ text: String) async throws -> ProfileHeaderUI {
        // FIXME: ###, do not parse as DTO, parse with Registry
        let dto = try ProfileHeaderUI(json: text)
        profiles.append(dto)
        postArea(PSPAreaProfile)
        return dto
    }

    func profileUpdate(_ json: String) async throws -> ProfileHeaderUI {
        // FIXME: ###
        postArea(PSPAreaProfile)
        fatalError()
    }

    func profileDup(_ id: String) async throws -> ProfileHeaderUI {
        // FIXME: ###
        postArea(PSPAreaProfile)
        fatalError()
    }

    func profileDelete(_ id: String) async throws {
        // FIXME: ###
        postArea(PSPAreaProfile)
        fatalError()
    }

    // MARK: - Tunnel

    func tunnelGetAll() -> [ProfileID: TunnelStatusUI] {
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
