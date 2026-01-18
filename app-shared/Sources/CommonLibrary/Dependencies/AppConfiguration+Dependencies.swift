// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Drop import
import Partout

extension ABI.AppConfiguration {
    @MainActor
    public func newConfigManager(
        isBeta: @escaping @Sendable () async -> Bool,
        fetcher: @escaping @Sendable (URL) async throws -> Data
    ) -> ConfigManager {
#if DEBUG
        let configURL = Bundle.main.url(forResource: "test-bundle", withExtension: "json")!
#else
        let configURL = constants.websites.config
#endif
        let betaConfigURL = constants.websites.betaConfig
        return ConfigManager(
            strategy: GitHubConfigStrategy(
                url: configURL,
                betaURL: betaConfigURL,
                ttl: constants.websites.configTTL,
                isBeta: isBeta,
                fetcher: fetcher
            ),
            buildNumber: buildNumber
        )
    }

    public func newAppRegistry(
        configManager: ConfigManager,
        kvStore: KeyValueStore
    ) -> Registry {
        newRegistry(
            deviceId: {
                if let existingId = kvStore.string(forAppPreference: .deviceId) {
                    pspLog(.core, .info, "Device ID: \(existingId)")
                    return existingId
                }
                let newId = String.random(count: constants.deviceIdLength)
                kvStore.set(newId, forAppPreference: .deviceId)
                pspLog(.core, .info, "Device ID (new): \(newId)")
                return newId
            }(),
            configBlock: { [weak configManager, weak kvStore] in
                guard let configManager, let kvStore else { return [] }
                return kvStore.preferences.enabledFlags(of: configManager.activeFlags)
            }
        )
    }

    public func newTunnelRegistry(
        preferences: ABI.AppPreferenceValues
    ) -> Registry {
        assert(preferences.deviceId != nil, "No Device ID found in preferences")
        pspLog(.core, .info, "Device ID: \(preferences.deviceId ?? "not set")")
        return newRegistry(
            deviceId: preferences.deviceId ?? "MissingDeviceID",
            configBlock: {
                preferences.enabledFlags()
            }
        )
    }

    @MainActor
    public func newIAPManager(
        inAppHelper: InAppHelper,
        receiptReader: UserInAppReceiptReader,
        betaChecker: BetaChecker
    ) -> IAPManager {
        IAPManager(
            customUserLevel: customUserLevel,
            inAppHelper: inAppHelper,
            receiptReader: receiptReader,
            betaChecker: betaChecker,
            timeoutInterval: constants.iap.productsTimeoutInterval,
            verificationDelayMinutesBlock: {
                constants.tunnel.verificationDelayMinutes(isBeta: $0)
            },
            productsAtBuild: newProductsAtBuild
        )
    }

    public func newProductsAtBuild(purchase: ABI.OriginalPurchase) -> Set<ABI.AppProduct> {
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

    @MainActor
    public func newAppProfileProcessor(
        iapManager: IAPManager?,
        preview: @escaping @Sendable (Profile) -> ABI.ProfilePreview
    ) -> ProfileProcessor {
        DefaultProfileProcessor(
            iapManager: iapManager,
            preview: preview
        )
    }

    public func newAppTunnelProcessor(
        apiManager: APIManager?,
        registry: Registry,
        providerServerSorter: @escaping ProviderServerParameters.Sorter
    ) -> AppTunnelProcessor {
        DefaultAppTunnelProcessor(
            apiManager: apiManager,
            registry: registry,
            title: {
                String(format: constants.tunnel.profileTitleFormat, $0.name)
            },
            providerServerSorter: providerServerSorter
        )
    }

    public func newTunnelProcessor() -> PacketTunnelProcessor {
        DefaultTunnelProcessor()
    }

    @MainActor
    public func newTunnelManager(
        tunnel: Tunnel,
        extensionInstaller: ExtensionInstaller?,
        kvStore: KeyValueStore,
        processor: AppTunnelProcessor
    ) -> TunnelManager {
        TunnelManager(
            tunnel: tunnel,
            extensionInstaller: extensionInstaller,
            kvStore: kvStore,
            processor: processor,
            interval: constants.tunnel.refreshInterval
        )
    }

    @MainActor
    public func newVersionChecker(
        kvStore: KeyValueStore,
        downloadURL: URL,
        fetcher: @escaping @Sendable (URL) async throws -> Data
    ) -> VersionChecker {
        let versionStrategy = GitHubReleaseStrategy(
            releaseURL: constants.github.latestRelease,
            rateLimit: constants.api.versionRateLimit,
            fetcher: fetcher
        )
        return VersionChecker(
            kvStore: kvStore,
            strategy: versionStrategy,
            currentVersion: versionNumber,
            downloadURL: downloadURL
        )
    }

    public func newWebPasscodeGenerator() -> String {
        let length = constants.webReceiver.passcodeLength
        let upperBound = Int(pow(10, Double(length)))
        return String(format: "%0\(length)d", Int.random(in: 0..<upperBound))
    }
}

// MARK: - Apple

#if canImport(CommonLibraryApple)

extension ABI.AppConfiguration {
    public enum BundleKey: String, CaseIterable, Decodable, Sendable {
        // These cases are all strings
        case appStoreId
        case cloudKitId
        case groupId
        case iapBundlePrefix
        case keychainGroupId
        case loginItemId
        case tunnelId

        // This is an integer number
        case userLevel

        static func requiredKeys(for target: ABI.BuildTarget) -> Set<Self> {
            switch target {
            case .app: Set(allCases).subtracting([.userLevel])
            case .tunnel: [.groupId, .keychainGroupId, .tunnelId]
            }
        }
    }

    public init(
        constants: ABI.Constants,
        distributionTarget: ABI.DistributionTarget,
        buildTarget: ABI.BuildTarget,
        bundle: BundleConfiguration
    ) {
        let displayName = bundle.displayName
        let versionNumber = bundle.versionNumber
        let buildNumber = bundle.buildNumber
        let versionString = bundle.versionString

        // Ensure that all required keys are present (will crash on first missing)
        let requiredBundleKeys = BundleKey.requiredKeys(for: buildTarget)
        let bundleStrings = requiredBundleKeys.reduce(into: [:]) {
            $0[$1.rawValue] = bundle.string(for: $1)
        }

        // Fetch user level manually
        let customUserLevel = bundle.integerIfPresent(for: .userLevel).map {
            ABI.AppUserLevel(rawValue: $0)
        } ?? nil

        let log = SimpleLogDestination()

        let appGroupURL = {
            let groupId = bundle.string(for: .groupId)
            guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
                log.append(.error, "Unable to access App Group container")
                return FileManager.default.temporaryDirectory
            }
            return url
        }()

        let urlForAppLog = appGroupURL.forCaches.appending(path: constants.log.appPath)
        let urlForTunnelLog = {
            let baseURL: URL
            if distributionTarget.supportsAppGroups {
                baseURL = appGroupURL.forCaches
            } else {
                let fm: FileManager = .default
                baseURL = fm.temporaryDirectory
                do {
                    try fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
                } catch {
                    log.append(.error, "Unable to create temporary directory \(baseURL): \(error)")
                }
            }
            return baseURL.appending(path: constants.log.tunnelPath)
        }()

        let urlForReview: URL?
        if requiredBundleKeys.contains(.appStoreId) {
            urlForReview = {
                let appStoreId = bundle.string(for: .appStoreId)
                guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review") else {
                    fatalError("Unable to build urlForReview")
                }
                return url
            }()
        } else {
            urlForReview = nil
        }

        self.init(
            constants: constants,
            distributionTarget: distributionTarget,
            displayName: displayName,
            versionNumber: versionNumber,
            buildNumber: buildNumber,
            versionString: versionString,
            customUserLevel: customUserLevel,
            bundleStrings: bundleStrings,
            urlForAppLog: urlForAppLog,
            urlForTunnelLog: urlForTunnelLog,
            urlForReview: urlForReview
        )
    }

    public func bundleString(for key: ABI.AppConfiguration.BundleKey) -> String {
        guard let value = bundleStrings[key.rawValue] else {
            fatalError("Missing bundle value in JSON for: \(key.rawValue)")
        }
        return value
    }
}

private extension BundleConfiguration {
    func string(for key: ABI.AppConfiguration.BundleKey) -> String {
        guard let value: String = value(forKey: key.rawValue) else {
            fatalError("Missing main bundle key: \(key.rawValue)")
        }
        return value
    }

    func integerIfPresent(for key: ABI.AppConfiguration.BundleKey) -> Int? {
        value(forKey: key.rawValue)
    }
}

// App Group container is not available on tvOS (#1007)

#if !os(tvOS)

private extension URL {
    var forCaches: Self {
        let url = appending(components: "Library", "Caches")
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            SimpleLogDestination().append(.fault, "Unable to create group caches directory: \(error)")
        }
        return url
    }

    var forDocuments: Self {
        let url = appending(components: "Library", "Documents")
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            SimpleLogDestination().append(.fault, "Unable to create group documents directory: \(error)")
        }
        return url
    }
}

#else

private extension URL {
    var forCaches: URL {
        do {
            return try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            SimpleLogDestination().append(.fault, "Unable to create user documents directory: \(error)")
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }

    var forDocuments: URL {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            SimpleLogDestination().append(.fault, "Unable to create user documents directory: \(error)")
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }
}

#endif

// MARK: Dependencies

extension ABI.AppConfiguration {
    public func newKeyValueStore() -> KeyValueStore {
        UserDefaultsStore(.standard)
    }

    public func newLogFormatter() -> LogFormatter {
        FoundationLogFormatter(
            dateFormat: constants.log.formatter.timestamp,
            messageFormat: constants.log.formatter.message
        )
    }

    public func newAppTunnelEnvironment(strategy: TunnelStrategy, profileId: Profile.ID) -> TunnelEnvironmentReader {
        if distributionTarget.supportsAppGroups {
            return newTunnelEnvironment(profileId: profileId)
        } else {
            guard let neStrategy = strategy as? NETunnelStrategy else {
                fatalError("NETunnelEnvironment requires NETunnelStrategy")
            }
            return NETunnelEnvironment(strategy: neStrategy, profileId: profileId)
        }
    }

    public func newTunnelEnvironment(profileId: Profile.ID) -> TunnelEnvironment {
        let appGroup = bundleString(for: .groupId)
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            fatalError("No access to App Group: \(appGroup)")
        }
        return UserDefaultsEnvironment(profileId: profileId, defaults: defaults)
    }

    public func newNEProtocolCoder(_ ctx: PartoutLoggerContext, registry: Registry) -> NEProtocolCoder {
        if distributionTarget.supportsAppGroups {
            return KeychainNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: bundleString(for: .tunnelId),
                registry: registry,
                keychain: AppleKeychain(ctx, group: bundleString(for: .keychainGroupId))
            )
        } else {
            return ProviderNEProtocolCoder(
                ctx,
                tunnelBundleIdentifier: bundleString(for: .tunnelId),
                registry: registry
            )
        }
    }

    public func newBetaChecker() -> BetaChecker {
        TestFlightChecker()
    }

    @MainActor
    public func newAppProductHelper() -> InAppHelper {
        StoreKitHelper(
            products: ABI.AppProduct.all,
            inAppIdentifier: {
                let iapBundlePrefix = bundleString(for: .iapBundlePrefix)
                return "\(iapBundlePrefix).\($0.rawValue)"
            }
        )
    }

    public func newSystemExtensionManager(tunnelIdentifier: String) -> ExtensionInstaller? {
        guard distributionTarget == .developerID else {
            return nil
        }
        return SystemExtensionManager(
            identifier: tunnelIdentifier,
            version: versionNumber,
            build: buildNumber
        )
    }

#if os(tvOS)
    @MainActor
    public func newWebReceiverManager(
        htmlPath: String,
        stringsBundle: Bundle
    ) -> WebReceiverManager {
        let receiver = NIOWebReceiver(
            htmlPath: htmlPath,
            stringsBundle: stringsBundle,
            port: constants.webReceiver.port
        )
        return WebReceiverManager(webReceiver: receiver) {
            newWebPasscodeGenerator()
        }
    }
#endif
}

#endif
