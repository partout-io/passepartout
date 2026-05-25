// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class AppPreferencesStore: @unchecked Sendable {
    public typealias UpdateBlock = (ABI.AppPreferences) -> Void

    private var backend: ABI.AppPreferencesProtocol
    public var onUpdate: UpdateBlock?

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

    public func update(
        silent: Bool = false,
        _ body: (inout any ABI.AppPreferencesProtocol) -> Void
    ) {
        body(&backend)
        if !silent {
            onUpdate?(backend.serialized())
        }
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
