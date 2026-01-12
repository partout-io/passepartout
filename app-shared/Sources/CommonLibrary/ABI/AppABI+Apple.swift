// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)
import CommonData
import CommonDataPreferences
import CommonDataProfiles
import CommonDataProviders
import CoreData

extension AppABI {
    public static func forProduction(
        appConfiguration: ABI.AppConfiguration,
        kvStore: KeyValueStore,
        assertModule: (ModuleType, Registry) -> Void,
        profilePreview: @escaping @Sendable (Profile) -> ABI.ProfilePreview,
        apiMappers: [APIMapper],
        webHTMLPath: String?,
        webStringsBundle: Bundle?,
        withUITesting: Bool,
        withFakeIAPs: Bool
    ) -> AppABI {
        let logFormatter = appConfiguration.newLogFormatter()
        let ctx = PartoutLogger.register(
            for: .app,
            with: appConfiguration,
            preferences: kvStore.preferences,
            mapper: { [weak logFormatter] in
                logFormatter?.formattedLog(timestamp: $0.timestamp, message: $0.message) ?? $0.message
            }
        )
        let appLogger = appConfiguration.newAppLogger()

        // MARK: Config (GitHub)

        let betaChecker = appConfiguration.newBetaChecker()
        let configManager = appConfiguration.newConfigManager(
            isBeta: {
                await betaChecker.isBeta()
            },
            fetcher: {
                var request = URLRequest(url: $0)
                request.cachePolicy = .reloadIgnoringCacheData
                return try await URLSession.shared.data(for: request).0
            }
        )

        // MARK: Registry

        let registry = appConfiguration.newAppRegistry(
            appLogger: appLogger,
            configManager: configManager,
            kvStore: kvStore
        )

        // Ensure that all module builders can be rendered in the profile editor
        ModuleType.allCases.forEach { moduleType in
            assertModule(moduleType, registry)
        }

        // MARK: Persistence (Core Data)

        guard let cdLocalModel = NSManagedObjectModel.mergedModel(from: [
            CommonData.providersBundle
        ]) else {
            fatalError("Unable to load local model")
        }
        guard let cdRemoteModel = NSManagedObjectModel.mergedModel(from: [
            CommonData.profilesBundle,
            CommonData.preferencesBundle
        ]) else {
            fatalError("Unable to load remote model")
        }
        let localStore = CoreDataPersistentStore(
            logger: appLogger,
            containerName: appConfiguration.constants.containers.local,
            model: cdLocalModel,
            cloudKitIdentifier: nil,
            author: nil
        )
        let newRemoteStore: (_ cloudKit: Bool) -> CoreDataPersistentStore = { isEnabled in
            let cloudKitIdentifier: String?
            if isEnabled && appConfiguration.distributionTarget.supportsCloudKit {
                cloudKitIdentifier = appConfiguration.bundleString(for: .cloudKitId)
            } else {
                cloudKitIdentifier = nil
            }
            return CoreDataPersistentStore(
                logger: appLogger,
                containerName: appConfiguration.constants.containers.remote,
                model: cdRemoteModel,
                cloudKitIdentifier: cloudKitIdentifier,
                author: nil
            )
        }

        // MARK: IAP (StoreKit)

        let iapManager = appConfiguration.newIAPManager(
            inAppHelper: appConfiguration.simulatedAppProductHelper(isFake: withFakeIAPs),
            receiptReader: appConfiguration.simulatedAppReceiptReader(isFake: withFakeIAPs, logger: appLogger),
            betaChecker: betaChecker
        )

        // MARK: API

        let apiManager = APIManager(
            ctx,
            from: apiMappers,
            repository: CommonData.cdAPIRepositoryV3(
                context: localStore.backgroundContext()
            )
        )

        // MARK: Profiles and Tunnel (NE)

        let appEncoder = AppEncoder(registry: registry)
        let tunnelIdentifier = appConfiguration.bundleString(for: .tunnelId)
        let tunnelProcessor = appConfiguration.newAppTunnelProcessor(
            apiManager: apiManager,
            registry: registry,
            providerServerSorter: {
                $0.sort(using: $1.sortingComparators)
            }
        )
#if targetEnvironment(simulator)
        let tunnelStrategy = FakeTunnelStrategy()
        let mainProfileRepository = appConfiguration.newBackupProfileRepository(
            logger: appLogger,
            encoder: appEncoder,
            model: cdRemoteModel,
            name: appConfiguration.constants.containers.backup,
            observingResults: true
        )
        let backupProfileRepository: ProfileRepository? = nil
#else
        let tunnelStrategy = NETunnelStrategy(
            ctx,
            bundleIdentifier: tunnelIdentifier,
            coder: appConfiguration.newNEProtocolCoder(ctx, registry: registry)
        )
        let mainProfileRepository = NEProfileRepository(repository: tunnelStrategy) { [weak tunnelProcessor] in
            tunnelProcessor?.title(for: $0) ?? $0.name
        }
        let backupProfileRepository = appConfiguration.newBackupProfileRepository(
            logger: appLogger,
            encoder: appEncoder,
            model: cdRemoteModel,
            name: appConfiguration.constants.containers.backup,
            observingResults: false
        )
#endif
        let profileProcessor = appConfiguration.newAppProfileProcessor(
            iapManager: iapManager,
            preview: profilePreview
        )
        let profileManager = ProfileManager(
            processor: profileProcessor,
            repository: mainProfileRepository,
            backupRepository: backupProfileRepository,
            mirrorsRemoteRepository: false
        )
        let tunnel = Tunnel(ctx, strategy: tunnelStrategy) {
            appConfiguration.newAppTunnelEnvironment(strategy: tunnelStrategy, profileId: $0)
        }
        let sysexManager = appConfiguration.newSystemExtensionManager(
            tunnelIdentifier: tunnelIdentifier
        )
        let tunnelManager = appConfiguration.newTunnelManager(
            tunnel: tunnel,
            extensionInstaller: sysexManager,
            kvStore: kvStore,
            processor: tunnelProcessor
        )

        // MARK: Preferences (Core Data)

        let preferencesManager = PreferencesManager()

        // MARK: Version (GitHub)

        let versionChecker = appConfiguration.newVersionChecker(
            kvStore: kvStore,
            downloadURL: {
                switch appConfiguration.distributionTarget {
                case .appStore:
                    return appConfiguration.constants.websites.appStoreDownload
                case .developerID:
                    return appConfiguration.constants.websites.macDownload
                case .enterprise:
                    fatalError("No URL for enterprise distribution")
                }
            }(),
            fetcher: {
                var request = URLRequest(url: $0)
                request.cachePolicy = .useProtocolCachePolicy
                return try await URLSession.shared.data(for: request).0
            }
        )

        // MARK: Web (NIO)

        let webReceiverManager: WebReceiverManager
#if os(tvOS)
        if let webHTMLPath, let webStringsBundle {
            webReceiverManager = appConfiguration.newWebReceiverManager(
                appLogger: appLogger,
                htmlPath: webHTMLPath,
                stringsBundle: webStringsBundle
            )
        } else {
            webReceiverManager = WebReceiverManager()
        }
#else
        webReceiverManager = WebReceiverManager()
#endif

        // MARK: Sync (CloudKit)

        // Remote profiles and preferences are (re)created on updates to synchronization
        let onEligibleFeaturesBlock: (Set<ABI.AppFeature>) async -> Void = { @MainActor features in
            let isRemoteImportingEnabled = features.contains(.sharing)

            // Toggle CloudKit sync based on .sharing eligibility
            let remoteStore = newRemoteStore(isRemoteImportingEnabled)

            if appConfiguration.distributionTarget.supportsCloudKit {
                // @Published
                profileManager.isRemoteImportingEnabled = isRemoteImportingEnabled

                let isCloudKitEnabled = withUITesting || appConfiguration.isCloudKitEnabled
                appLogger.log(.core, .info, "\tRefresh remote sync (eligible=\(isRemoteImportingEnabled), CloudKit=\(isCloudKitEnabled))...")
                appLogger.log(.profiles, .info, "\tRefresh remote profiles repository (sync=\(isRemoteImportingEnabled))...")

                let remoteProfileRepository = CommonData.cdProfileRepositoryV3(
                    encoder: appEncoder,
                    context: remoteStore.context,
                    observingResults: true,
                    onResultError: { [weak appLogger] in
                        appLogger?.log(.profiles, .error, "Unable to decode remote profile: \($0)")
                        return .ignore
                    }
                )
                do {
                    try await profileManager.observeRemote(repository: remoteProfileRepository)
                } catch {
                    appLogger.log(.profiles, .error, "\tUnable to re-observe remote profiles: \(error)")
                }
            }

            appLogger.log(.core, .info, "\tRefresh modules preferences repository...")
            preferencesManager.modulesRepositoryFactory = {
                try CommonData.cdModulePreferencesRepositoryV3(
                    context: remoteStore.context,
                    moduleId: $0
                )
            }

            appLogger.log(.core, .info, "\tRefresh providers preferences repository...")
            preferencesManager.providersRepositoryFactory = {
                try CommonData.cdProviderPreferencesRepositoryV3(
                    context: remoteStore.context,
                    providerId: $0
                )
            }

            appLogger.log(.profiles, .info, "\tReload profiles required features...")
            profileManager.reloadRequiredFeatures()
        }

        return AppABI(
            apiManager: apiManager,
            appConfiguration: appConfiguration,
            appEncoder: appEncoder,
            appLogger: appLogger,
            configManager: configManager,
            extensionInstaller: sysexManager,
            iapManager: iapManager,
            kvStore: kvStore,
            logFormatter: logFormatter,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            tunnelManager: tunnelManager,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager,
            onEligibleFeaturesBlock: onEligibleFeaturesBlock
        )
    }
}

private extension ABI.AppConfiguration {
    var isCloudKitEnabled: Bool {
#if os(tvOS)
        true
#else
        FileManager.default.ubiquityIdentityToken != nil
#endif
    }

    func newBackupProfileRepository(
        logger: AppLogger,
        encoder: AppEncoder,
        model: NSManagedObjectModel,
        name: String,
        observingResults: Bool
    ) -> ProfileRepository {
        let store = CoreDataPersistentStore(
            logger: logger,
            containerName: name,
            model: model,
            cloudKitIdentifier: nil,
            author: nil
        )
        return CommonData.cdProfileRepositoryV3(
            encoder: encoder,
            context: store.context,
            observingResults: observingResults,
            onResultError: {
                logger.log(.profiles, .error, "Unable to decode local profile: \($0)")
                return .ignore
            }
        )
    }

    @MainActor
    func simulatedAppProductHelper(isFake: Bool) -> InAppHelper {
        guard !isFake else {
            return FakeInAppHelper()
        }
        return newAppProductHelper()
    }

    @MainActor
    func simulatedAppReceiptReader(isFake: Bool, logger: AppLogger) -> UserInAppReceiptReader {
        guard !isFake else {
            guard let mockHelper = simulatedAppProductHelper(isFake: true) as? FakeInAppHelper else {
                fatalError("When .isFakeIAP, simulatedInAppHelper is expected to be MockAppProductHelper")
            }
            return mockHelper.receiptReader
        }
        return SharedReceiptReader(
            reader: StoreKitReceiptReader(logger: logger)
        )
    }
}
#endif
