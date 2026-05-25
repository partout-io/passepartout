// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class AppPreferencesStore: @unchecked Sendable {
    public typealias UpdateBlock = (ABI.AppPreferencesPatch) -> Void

    private var backend: ABI.AppPreferencesProtocol
    private let onUpdate: UpdateBlock?

    public init(
        _ backend: ABI.AppPreferencesProtocol = .default(),
        onUpdate: UpdateBlock? = nil
    ) {
        self.backend = backend
        self.onUpdate = onUpdate
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
        update {
            $0.deviceId = newId
        }
        pspLog(.core, .info, "Device ID (new): \(newId)")
        return newId
    }

    public subscript<V>(_ keyPath: KeyPath<ABI.AppPreferencesProtocol, V>) -> V {
        backend[keyPath: keyPath]
    }

    public func update(_ body: (inout any ABI.AppPreferencesProtocol) -> Void) {
        guard let onUpdate else {
            body(&backend)
            return
        }
        let old = serialized()
        body(&backend)
        let new = serialized()
        let patch = ABI.AppPreferencesPatch(from: old, to: new)
        onUpdate(patch)
    }

    public func isFlagEnabled(_ flag: ABI.ConfigFlag) -> Bool {
        backend.isFlagEnabled(flag)
    }

    public func enabledFlags(of flags: Set<ABI.ConfigFlag>? = nil) -> Set<ABI.ConfigFlag> {
        backend.enabledFlags(of: flags)
    }
}

// MARK: - Serialization

extension AppPreferencesStore {
    public func serialized() -> ABI.AppPreferences {
        backend.serialized()
    }

    public func apply(_ patch: ABI.AppPreferencesPatch) {
        update {
            $0.apply(patch)
        }
    }
}
