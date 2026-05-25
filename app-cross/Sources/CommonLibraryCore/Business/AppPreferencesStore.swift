// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class AppPreferencesStore: @unchecked Sendable {
    private var backend: ABI.AppPreferencesProtocol

    public init(_ backend: ABI.AppPreferencesProtocol = .default()) {
        self.backend = backend
    }

    public func serialized() -> ABI.AppPreferences {
        backend.serialized()
    }

    public subscript<V>(_ keyPath: KeyPath<ABI.AppPreferencesProtocol, V>) -> V {
        backend[keyPath: keyPath]
    }

    public func update(_ body: (inout any ABI.AppPreferencesProtocol) -> Void) {
        let old = serialized()
        body(&backend)
        let new = serialized()
//        let patch = emitChanges(from: old, to: new)
    }

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

    public func isFlagEnabled(_ flag: ABI.ConfigFlag) -> Bool {
        backend.isFlagEnabled(flag)
    }

    public func enabledFlags(of flags: Set<ABI.ConfigFlag>? = nil) -> Set<ABI.ConfigFlag> {
        backend.enabledFlags(of: flags)
    }
}
