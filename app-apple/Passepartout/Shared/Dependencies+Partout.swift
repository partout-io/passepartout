// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

extension Dependencies {
    @MainActor
    var kvManager: KeyValueManager {
        Self.sharedKVStore
    }

    func newRegistry(
        deviceId: String,
        configBlock: @escaping @Sendable () -> Set<ABI.ConfigFlag>
    ) -> Registry {
        Registry(
            providerResolvers: [
                OpenVPNProviderResolver(.global),
                WireGuardProviderResolver(.global, deviceId: deviceId)
            ],
            allImplementations: [
                OpenVPNImplementationBuilder(
                    distributionTarget: distributionTarget,
                    configBlock: configBlock
                ).build(),
                WireGuardImplementationBuilder(
                    configBlock: configBlock
                ).build()
            ]
        )
    }

    func neProtocolCoder(_ ctx: PartoutLoggerContext, cfg: ABI.AppConfiguration, registry: Registry) -> NEProtocolCoder {
        if distributionTarget.supportsAppGroups {
            return KeychainNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: cfg.bundleString(for: .tunnelId),
                registry: registry,
                keychain: AppleKeychain(ctx, group: cfg.bundleString(for: .keychainGroupId))
            )
        } else {
            return ProviderNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: cfg.bundleString(for: .tunnelId),
                registry: registry
            )
        }
    }

    func appTunnelEnvironment(cfg: ABI.AppConfiguration, strategy: TunnelStrategy, profileId: Profile.ID) -> TunnelEnvironmentReader {
        if distributionTarget.supportsAppGroups {
            return tunnelEnvironment(cfg: cfg, profileId: profileId)
        } else {
            guard let neStrategy = strategy as? NETunnelStrategy else {
                fatalError("NETunnelEnvironment requires NETunnelStrategy")
            }
            return NETunnelEnvironment(strategy: neStrategy, profileId: profileId)
        }
    }

    func tunnelEnvironment(cfg: ABI.AppConfiguration, profileId: Profile.ID) -> TunnelEnvironment {
        let appGroup = cfg.bundleString(for: .groupId)
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            fatalError("No access to App Group: \(appGroup)")
        }
        return UserDefaultsEnvironment(profileId: profileId, defaults: defaults)
    }
}

private extension Dependencies {
    @MainActor
    static let sharedKVStore: KeyValueManager = KeyValueManager(
        store: UserDefaultsStore(.standard),
        fallback: ABI.AppPreferenceValues()
    )
}
