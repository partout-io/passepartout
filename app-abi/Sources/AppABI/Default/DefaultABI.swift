// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C
import CommonLibrary

// FIXME: ###, free psp_json after use
final class DefaultABI: ABIProtocol {
    private var eventContext: UnsafeMutableRawPointer?
    private var eventCallback: psp_event_callback?

    // FIXME: ###, business objects, this should map most of AppContext
    private let registry: Registry
    private let profileManager: ProfileManager

    init() {
        registry = Registry()
        profileManager = .init(profiles: [])
    }

    func initialize(eventContext: UnsafeMutableRawPointer?, eventCallback: psp_event_callback?) {
        self.eventContext = eventContext
        self.eventCallback = eventCallback
    }

    // MARK: - Profiles

    func profileGetHeaders() -> [ProfileHeaderUI] {
        profileManager.previews.map(\.uiPreview)
    }

    // FIXME: ###, name from args, or from internal constants?
    func profileNew() async throws -> ProfileHeaderUI {
        let name = profileManager.firstUniqueName(from: "lorem ipsum")
        let profile = try Profile.Builder(name: name).build()
        try await profileManager.save(profile)
        postArea(PSPAreaProfile)
        return profile.uiPreview
    }

    func profileImportText(_ text: String) async throws -> ProfileHeaderUI {
        let profile = try registry.compatibleProfile(fromString: text)
        try await profileManager.save(profile)
        postArea(PSPAreaProfile)
        return profile.uiPreview
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

    func tunnelGetAll() -> [ProfileID : TunnelStatusUI] {
        // FIXME: ###
        [:]
    }

    func tunnelSetEnabled(_ enabled: Bool, profileId: String) {
//        let dtoId = String(cString: profileId)
//        statuses[dtoId] = enabled ? .connected : .disconnected
        postArea(PSPAreaTunnel)
    }
}

private extension DefaultABI {
    func postArea(_ area: psp_area) {
        eventCallback?(eventContext, psp_event(area: area))
    }
}
