// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.AppConfiguration {
    public func makeAppProfileProcessor(iapManager: IAPManager?) -> ProfileProcessor {
        DefaultProfileProcessor(iapManager: iapManager)
    }

    public func makeAppTunnelEnvironment(strategy: TunnelStrategy, profileId: Profile.ID) -> TunnelEnvironmentReader {
        if bundle.distributionTarget.supportsAppGroups {
            return makeTunnelEnvironment(profileId: profileId)
        } else if let fetcher = strategy as? EnvironmentFetcher {
            return NETunnelEnvironment(profileId: profileId) { [weak fetcher] in
                try await fetcher?.fetchEnvironment(profileId: $0)
            }
        } else {
            fatalError("NETunnelEnvironment requires EnvironmentFetcher")
        }
    }

    public func makeAppTunnelProcessor(
        profileRepository: ProfileRepository,
        extensionInstaller: ExtensionInstaller?
    ) -> AppTunnelProcessor {
        DefaultAppTunnelProcessor(
            profileRepository: profileRepository,
            extensionInstaller: extensionInstaller
        )
    }

    public func makeBetaChecker() -> BetaChecker {
        TestFlightChecker()
    }

    public func makeConfigManager(
        withTestBundle: Bool,
        isBeta: @escaping @Sendable () async -> Bool,
        fetcher: @escaping @Sendable (URL) async throws -> Data
    ) -> ConfigManager {
        let configURL: URL
        if withTestBundle {
            configURL = Bundle.main.url(forResource: "test-bundle", withExtension: "json")!
        } else {
            configURL = constants.websites.configURL
        }
        let betaConfigURL = constants.websites.betaConfigURL
        return ConfigManager(
            strategy: GitHubConfigStrategy(
                url: configURL,
                betaURL: betaConfigURL,
                ttl: constants.websites.configTTL,
                betaTTLFactor: constants.websites.betaTTLFactor,
                isBeta: isBeta,
                fetcher: fetcher
            ),
            buildNumber: bundle.buildNumber
        )
    }

    public func makeIAPManager(
        inAppHelper: InAppHelper,
        receiptReader: UserInAppReceiptReader,
        betaChecker: BetaChecker
    ) -> IAPManager {
        IAPManager(
            customUserLevel: bundle.customUserLevel,
            inAppHelper: inAppHelper,
            receiptReader: receiptReader,
            betaChecker: betaChecker,
            timeoutInterval: constants.iap.productsTimeoutInterval,
            verificationDelayMinutesBlock: {
                constants.tunnel.verificationDelayMinutes(isBeta: $0)
            },
            productsAtBuild: makeProductsAtBuild
        )
    }

    public func makeInAppHelper() -> InAppHelper {
        StoreKitHelper(
            products: ABI.AppProduct.all,
            inAppIdentifier: {
                let iapBundlePrefix = bundle.bundleString(for: .iapBundlePrefix)
                return "\(iapBundlePrefix).\($0.rawValue)"
            }
        )
    }

    public func makeInAppReceiptReader(
        modeBlock: @escaping @Sendable @BusinessActor () async -> StoreKitReceiptReader.Mode
    ) -> InAppReceiptReader {
        StoreKitReceiptReader(modeBlock: modeBlock)
    }

    public func makeKeychainAndNECoder(
        _ ctx: PartoutLoggerContext,
        bundleIdentifier: String,
        coder: ProfileCoder
    ) -> (keychain: Keychain, neCoder: NEProtocolCoder) {
        let keychain: Keychain
        let neCoder: NEProtocolCoder
        let tunnelIdentifier = bundle.bundleString(for: .tunnelId)
        if bundle.distributionTarget.supportsAppGroups {
            let appGroup = bundle.bundleString(for: .keychainGroupId)
            keychain = AppleKeychain(ctx, group: appGroup)
            neCoder = KeychainNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: tunnelIdentifier,
                coder: coder,
                keychain: keychain
            )
        } else {
            keychain = AppleKeychain(ctx, service: bundleIdentifier)
            neCoder = ProviderNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: tunnelIdentifier,
                coder: coder,
                uid: Int(getuid())
            )
        }
        return (keychain, neCoder)
    }

    public func makeKeychainTitle() -> @Sendable (Profile) -> String {
        {
            String(format: constants.tunnel.profileTitleFormat, $0.name)
        }
    }

    public func makeLogFormatter() -> LogFormatter {
        FoundationLogFormatter(
            dateFormat: constants.log.formatter.timestamp,
            messageFormat: constants.log.formatter.message
        )
    }

    public func makeNETunnelStrategy(
        _ ctx: PartoutLoggerContext,
        coder: NEProtocolCoder,
        source: AsyncStream<ProfilesEvent>
    ) -> NETunnelStrategy {
        let bundleIdentifier = bundle.bundleString(for: .tunnelId)
        return NETunnelStrategy(
            ctx,
            bundleIdentifier: bundleIdentifier,
            source: source,
            coder: coder,
            fingerprint: {
                ($0.attributes.fingerprint ?? $0.id)?.uuidString
            }
        )
    }

    @Sendable
    public func makeProductsAtBuild(purchase: ABI.OriginalPurchase) -> Set<ABI.AppProduct> {
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

    public func makeRequest(for url: URL, cached: Bool) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = cached ? .useProtocolCachePolicy : .reloadIgnoringCacheData
        request.timeoutInterval = constants.url.timeoutInterval
        do {
            return try await URLSession.shared.data(for: request).0
        } catch {
            throw ABI.AppError.urlRequestFailed(reason: error)
        }
    }

    public func makeSystemExtensionManager() -> SystemExtensionManager? {
        guard bundle.distributionTarget == .developerID else {
            return nil
        }
        return SystemExtensionManager(
            identifier: bundle.bundleString(for: .tunnelId),
            version: bundle.versionNumber,
            build: bundle.buildNumber
        )
    }

    public func makeTunnelDefaults() -> UserDefaults {
        if bundle.distributionTarget.supportsAppGroups {
            let appGroup = bundle.bundleString(for: .groupId)
            guard let groupDefaults = UserDefaults(suiteName: appGroup) else {
                fatalError("No access to App Group: \(appGroup)")
            }
            return groupDefaults
        } else {
            return .standard
        }
    }

    public func makeTunnelEnvironment(profileId: Profile.ID) -> TunnelEnvironment {
        UserDefaultsEnvironment(profileId: profileId, defaults: makeTunnelDefaults())
    }

    public func makeTunnelProcessor() -> PacketTunnelProcessor {
        DefaultTunnelProcessor()
    }

    public func makeVersionChecker(
        preferences: AppPreferencesStore,
        downloadURL: URL,
        fetcher: @escaping @Sendable (URL, _ cached: Bool) async throws -> Data
    ) -> VersionChecker {
        let versionStrategy = GitHubReleaseStrategy(
            releaseURL: constants.github.latestReleaseURL,
            changelogURL: {
                constants.github.urlForChangelog(ofBuild: $0)
            },
            rateLimit: constants.url.versionRateLimit,
            fetcher: fetcher
        )
        return VersionChecker(
            preferences: preferences,
            strategy: versionStrategy,
            currentVersion: bundle.versionNumber,
            downloadURL: downloadURL
        )
    }

    public func makeWebPasscodeGenerator() -> String {
        let length = constants.webReceiver.passcodeLength
        let upperBound = Int(pow(10, Double(length)))
        return String(format: "%0\(length)d", Int.random(in: 0..<upperBound))
    }

#if os(tvOS)
    public func makeWebReceiverManager(
        htmlPath: String,
        stringsBundle: Bundle
    ) -> WebReceiverManager {
        let receiver = NIOWebReceiver(
            htmlPath: htmlPath,
            stringsBundle: stringsBundle,
            port: constants.webReceiver.port
        )
        return WebReceiverManager(webReceiver: receiver) {
            makeWebPasscodeGenerator()
        }
    }
#endif
}

// MARK: - EnvironmentFetcher

private protocol EnvironmentFetcher: AnyObject, Sendable {
    func fetchEnvironment(profileId: Profile.ID) async throws -> StaticTunnelEnvironment?
}

extension NETunnelStrategy: EnvironmentFetcher {
    func fetchEnvironment(profileId: Profile.ID) async throws -> StaticTunnelEnvironment? {
        let output = try await sendMessage(.environment(), to: profileId)
        switch output {
        case .environment(let env):
            return env
        case nil:
            return nil
        default:
            throw PartoutError(.unhandled)
        }
    }
}
