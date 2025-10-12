// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import Foundation
import Partout

extension Dependencies {
    var kvManager: KeyValueManager {
        Self.sharedKVStore
    }

    nonisolated func newRegistry(
        distributionTarget: DistributionTarget,
        deviceId: String,
        configBlock: @escaping @Sendable () -> Set<ConfigFlag>
    ) -> Registry {
        Registry(
            withKnown: true,
            providerResolvers: {
                var resolvers: [ProviderModuleResolver] = []
                resolvers.append(OpenVPNProviderResolver(.global))
                resolvers.append(WireGuardProviderResolver(.global, deviceId: deviceId))
                return resolvers
            }(),
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

    nonisolated func neProtocolCoder(_ ctx: PartoutLoggerContext, registry: Registry) -> NEProtocolCoder {
        if Self.distributionTarget.supportsAppGroups {
            return KeychainNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: BundleConfiguration.mainString(for: .tunnelId),
                registry: registry,
                keychain: AppleKeychain(ctx, group: BundleConfiguration.mainString(for: .keychainGroupId))
            )
        } else {
            return ProviderNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: BundleConfiguration.mainString(for: .tunnelId),
                registry: registry
            )
        }
    }

    nonisolated func appTunnelEnvironment(strategy: TunnelStrategy, profileId: Profile.ID) -> TunnelEnvironmentReader {
        if Self.distributionTarget.supportsAppGroups {
            return tunnelEnvironment(profileId: profileId)
        } else {
            guard let neStrategy = strategy as? NETunnelStrategy else {
                fatalError("NETunnelEnvironment requires NETunnelStrategy")
            }
            return NETunnelEnvironment(strategy: neStrategy, profileId: profileId)
        }
    }

    nonisolated func tunnelEnvironment(profileId: Profile.ID) -> TunnelEnvironment {
        let appGroup = BundleConfiguration.mainString(for: .groupId)
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            fatalError("No access to App Group: \(appGroup)")
        }
        return UserDefaultsEnvironment(profileId: profileId, defaults: defaults)
    }
}

private extension Dependencies {
    static let sharedKVStore: KeyValueManager = KeyValueManager(
        store: UserDefaultsStore(.standard),
        fallback: AppPreferenceValues()
    )
}
