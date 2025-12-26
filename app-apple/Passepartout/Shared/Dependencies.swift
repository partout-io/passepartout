// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary

struct Dependencies {
    let appConfiguration: ABI.AppConfiguration
    let logFormatter: DateFormatter

    init(buildTarget: ABI.BuildTarget) {
        appConfiguration = Resources.newAppConfiguration(
            distributionTarget: Self.currentDistributionTarget,
            buildTarget: buildTarget
        )
        logFormatter = DateFormatter()
        logFormatter.dateFormat = appConfiguration.constants.log.formatter.timestamp
    }

    // MARK: Partout

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

    // MARK: CommonLibrary

    func newKVStore() -> KeyValueStore {
        UserDefaultsStore(.standard)
    }

    func appLogger() -> AppLogger {
        PartoutAppLogger(formattedLogBlock: formattedLog)
    }

    func formattedLog(timestamp: Date, message: String) -> String {
        let messageFormat = appConfiguration.constants.log.formatter.message
        let formattedTimestamp = logFormatter.string(from: timestamp)
        return String(format: messageFormat, formattedTimestamp, message)
    }

    @MainActor
    func appProductHelper() -> any AppProductHelper {
        StoreKitHelper(
            products: ABI.AppProduct.all,
            inAppIdentifier: {
                let prefix = appConfiguration.bundleString(for: .iapBundlePrefix)
                return "\(prefix).\($0.rawValue)"
            }
        )
    }

    func betaChecker() -> BetaChecker {
        TestFlightChecker()
    }

    func productsAtBuild() -> BuildProducts<ABI.AppProduct> {
        { purchase in
#if os(iOS)
            if purchase.isUntil(.freemium) {
                return [.Essentials.iOS]
            } else if purchase.isUntil(.v2) {
                return [.Features.networkSettings]
            }
            return []
#elseif os(macOS)
            if purchase.isUntil(.v2) {
                return [.Features.networkSettings]
            }
            return []
#else
            return []
#endif
        }
    }
}

private extension Dependencies {
    static var currentDistributionTarget: ABI.DistributionTarget {
#if PP_BUILD_MAC
        .developerID
#else
        .appStore
#endif
    }
}
