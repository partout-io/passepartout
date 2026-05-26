// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class AppPreferencesStore: @unchecked Sendable {
    public typealias RequestBlock = (ABI.AppPreferences, Set<ABI.NonUserFacingAppPreferenceKey>) -> Void

    private var backend: ABI.AppPreferencesProtocol
    public var onRequest: RequestBlock?

    public init(
        _ backend: ABI.AppPreferencesProtocol = .default(),
        onRequest: RequestBlock? = nil
    ) {
        self.backend = backend
        self.onRequest = onRequest
    }
}

// MARK: - CRUD

extension AppPreferencesStore {
    // Read or generate Device ID if needed
    public func configureDeviceId(length: Int) -> String {
        if let deviceId = self[\.deviceId] {
            pspLog(.core, .info, "Device ID: \(deviceId)")
            return deviceId
        }
        let newId = String.random(count: length)
        request(changesTo: [.deviceId]) {
            $0.deviceId = newId
        }
        pspLog(.core, .info, "Device ID (new): \(newId)")
        return newId
    }

    public subscript<V>(_ keyPath: KeyPath<ABI.AppPreferencesProtocol, V>) -> V {
        backend[keyPath: keyPath]
    }

    public func overwrite(
        _ body: (inout any ABI.AppPreferencesProtocol) -> Void
    ) {
        body(&backend)
    }

    public func request(
        changesTo fields: Set<ABI.NonUserFacingAppPreferenceKey>,
        _ body: (inout ABI.AppPreferencesProtocol) -> Void
    ) {
        if let onRequest {
            var copy: ABI.AppPreferencesProtocol = backend.serialized()
            body(&copy)
            onRequest(copy.serialized(), fields)
            return
        }
        body(&backend)
    }

    public func serialized() -> ABI.AppPreferences {
        backend.serialized()
    }

    public func isFlagEnabled(_ flag: ABI.ConfigFlag) -> Bool {
        backend.isFlagEnabled(flag)
    }

    public func enabledFlags(of flags: Set<ABI.ConfigFlag>? = nil) -> Set<ABI.ConfigFlag> {
        backend.enabledFlags(of: flags)
    }
}
