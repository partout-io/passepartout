// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@preconcurrency import NetworkExtension
import Partout

public actor NETunnelProfileMigrator {
    public typealias LoadManagers =
        @Sendable () async throws -> [NETunnelProviderManager]

    private let tunnelBundleIdentifier: String
    private let keychain: Keychain
    private let profileCoder: ProfileCoder
    private let protocolCoder: NEProtocolCoder
    private let label: @Sendable (Profile) -> String
    private let loadManagers: LoadManagers
    private let isComplete: @Sendable () -> Bool
    private let markComplete: @Sendable () -> Void

    public init(
        tunnelBundleIdentifier: String,
        keychain: Keychain,
        profileCoder: ProfileCoder,
        protocolCoder: NEProtocolCoder,
        label: @escaping @Sendable (Profile) -> String,
        loadManagers: @escaping LoadManagers = {
            try await NETunnelProviderManager.loadAllFromPreferences()
        },
        isComplete: @escaping @Sendable () -> Bool,
        markComplete: @escaping @Sendable () -> Void
    ) {
        self.tunnelBundleIdentifier = tunnelBundleIdentifier
        self.keychain = keychain
        self.profileCoder = profileCoder
        self.protocolCoder = protocolCoder
        self.label = label
        self.loadManagers = loadManagers
        self.isComplete = isComplete
        self.markComplete = markComplete
    }

    public func run() async {
        guard !isComplete() else {
            return
        }

        let managers: [NETunnelProviderManager]
        do {
            managers = try await loadManagers()
        } catch {
            // Keep the marker unset and retry later, but do not block fetchProfiles().
            pspLog(.profiles, .error, "Unable to load managers for migration: \(error)")
            return
        }

        var hasRetryableFailure = false

        for manager in managers {
            guard let proto = manager.protocolConfiguration as? NETunnelProviderProtocol,
                  proto.providerBundleIdentifier == tunnelBundleIdentifier,
                  let profileJSON = proto.providerConfiguration?["Profile"] as? String else {
                continue
            }

            let profile: Profile
            do {
                profile = try profileCoder.profile(fromString: profileJSON)
            } catch {
                // Terminal: retrying the same malformed payload cannot help.
                pspLog(.profiles, .error, "Unable to decode manager profile: \(error)")
                continue
            }

            guard protocolCoder.owns(proto, for: profile.id) else {
                continue
            }

            do {
                // The keychain becomes authoritative once it contains valid data.
                guard try !hasValidKeychainProfile(withId: profile.id) else {
                    continue
                }

                try keychain.set(
                    password: profileJSON,
                    for: profile.id.uuidString,
                    metadata: [
                        .label(label(profile)),
                        .comment(profile.attributes.fingerprint?.uuidString ?? "")
                    ]
                )

                // Intentionally do not remove the manager.
                // NETunnelStrategy will adopt it from the subsequent snapshot.
            } catch {
                hasRetryableFailure = true
                pspLog(.profiles, .error, "Unable to migrate profile \(profile.id): \(error)")
            }
        }

        if !hasRetryableFailure {
            markComplete()
        }
    }

    private func hasValidKeychainProfile(withId profileId: Profile.ID) throws -> Bool {
        let existingJSON: String
        do {
            existingJSON = try keychain.password(for: profileId.uuidString)
        } catch let error as PartoutError where error.code == .keychainItemNotFound {
            return false
        }
        do {
            _ = try profileCoder.profile(fromString: existingJSON)
            return true
        } catch {
            // Recover a corrupt entry from the manager copy.
            return false
        }
    }
}
