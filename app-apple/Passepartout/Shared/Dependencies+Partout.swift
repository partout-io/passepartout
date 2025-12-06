// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

extension Dependencies {
    func appLogger() -> AppLogger {
        PartoutLoggerStrategy(formattedLogBlock: formattedLog)
    }

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
                    distributionTarget: appConfiguration.distributionTarget,
                    configBlock: configBlock
                ).build(),
                WireGuardImplementationBuilder(
                    configBlock: configBlock
                ).build()
            ]
        )
    }

    func neProtocolCoder(_ ctx: PartoutLoggerContext, registry: Registry) -> NEProtocolCoder {
        if appConfiguration.distributionTarget.supportsAppGroups {
            return KeychainNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: appConfiguration.bundleString(for: .tunnelId),
                registry: registry,
                keychain: AppleKeychain(ctx, group: appConfiguration.bundleString(for: .keychainGroupId))
            )
        } else {
            return ProviderNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: appConfiguration.bundleString(for: .tunnelId),
                registry: registry
            )
        }
    }

    func appTunnelEnvironment(strategy: TunnelStrategy, profileId: Profile.ID) -> TunnelEnvironmentReader {
        if appConfiguration.distributionTarget.supportsAppGroups {
            return tunnelEnvironment(profileId: profileId)
        } else {
            guard let neStrategy = strategy as? NETunnelStrategy else {
                fatalError("NETunnelEnvironment requires NETunnelStrategy")
            }
            return NETunnelEnvironment(strategy: neStrategy, profileId: profileId)
        }
    }

    func tunnelEnvironment(profileId: Profile.ID) -> TunnelEnvironment {
        let appGroup = appConfiguration.bundleString(for: .groupId)
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
