// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)
import CommonData
import CommonDataPreferences
import CommonDataProfiles
import CommonDataProviders
import CoreData
import Partout

extension AppABI {
    public struct Result {
        public let abi: AppABI
        public let tunnelObservable: TunnelObservable
    }

    public static func forNetworkExtension(
        appConfiguration: ABI.AppConfiguration,
        preferences: AppPreferencesStore,
        assertModule: (ModuleType, ModuleRegistry) -> Void,
        apiMappers: [APIMapper],
        webHTMLPath: String?,
        webStringsBundle: Bundle?,
        withUITesting: Bool,
        withFakeIAPs: Bool
    ) -> Result {
        let deviceId = preferences.configureDeviceId(
            length: appConfiguration.constants.deviceIdLength
        )

        let logFormatter = appConfiguration.newLogFormatter()
        let ctx = pspLogRegister(
            for: .app,
            with: appConfiguration,
            preferences: preferences,
            localURL: appConfiguration.urlForAppLog,
            localMapper: logFormatter?.localMapper
        )
        pspLog(.core, .notice, "Partout \(PartoutConstants.version)")

        // MARK: Config (GitHub)

        let betaChecker = appConfiguration.newBetaChecker()
#if DEBUG
        let withTestBundle = true
#else
        let withTestBundle = false
#endif
        let configManager = appConfiguration.newConfigManager(
            withTestBundle: withTestBundle,
            isBeta: {
                await betaChecker.isBeta()
            },
            fetcher: {
                try await appConfiguration.newRequest(
                    for: $0,
                    cached: false,
                    bindings: nil
                )
            }
        )

        // MARK: Registry

        let cachesURL = FileManager.default.temporaryDirectory
        let registry = appConfiguration.newRegistryForApp(
            deviceId: deviceId,
            preferences: preferences,
            configManager: configManager,
            cachesURL: cachesURL
        )

        // Ensure that all module builders can be rendered in the profile editor
        ModuleType.knownTypes.forEach { moduleType in
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
            containerName: appConfiguration.constants.containers.local,
            model: cdLocalModel,
            cloudKitIdentifier: nil,
            author: nil
        )
        let newRemoteStore: (_ cloudKit: Bool) -> CoreDataPersistentStore = { isEnabled in
            let cloudKitIdentifier: String?
            if isEnabled && appConfiguration.bundle.distributionTarget.supportsCloudKit {
                cloudKitIdentifier = appConfiguration.bundle.bundleString(for: .cloudKitId)
            } else {
                cloudKitIdentifier = nil
            }
            return CoreDataPersistentStore(
                containerName: appConfiguration.constants.containers.remote,
                model: cdRemoteModel,
                cloudKitIdentifier: cloudKitIdentifier,
                author: nil
            )
        }

        // MARK: IAP (StoreKit)

        let iapHelper: InAppHelper
        let iapReceiptReader: UserInAppReceiptReader
        if !withFakeIAPs {
            iapHelper = appConfiguration.newInAppHelper()
            iapReceiptReader = SharedReceiptReader(
                reader: appConfiguration.newInAppReceiptReader {
                    // TODO: #1786, StoreKit receipt caching
                    .uncached
                }
            )
        } else {
            let fakeHelper = appConfiguration.newInAppFakeHelper()
            iapHelper = fakeHelper
            iapReceiptReader = fakeHelper.receiptReader
        }
        let iapManager = appConfiguration.newIAPManager(
            inAppHelper: iapHelper,
            receiptReader: iapReceiptReader,
            betaChecker: betaChecker
        )

        // MARK: API

        let apiManager = APIManager(
            from: apiMappers,
            repository: CommonData.cdAPIRepositoryV3(
                context: localStore.backgroundContext()
            )
        )

        // MARK: Profiles and Tunnel (NE)

        let sysexManager = appConfiguration.newSystemExtensionManager()
        let appEncoder = AppEncoder(coder: registry)
        let tunnelProcessor = appConfiguration.newAppTunnelProcessor(
            apiManager: apiManager,
            resolver: registry,
            extensionInstaller: sysexManager,
            providerServerSorter: {
                $0.sort(using: $1.sortingComparators)
            }
        )
#if targetEnvironment(simulator)
        let tunnelStrategy = FakeTunnelStrategy()
        let mainProfileRepository = appConfiguration.newBackupProfileRepository(
            encoder: appEncoder,
            model: cdRemoteModel,
            name: appConfiguration.constants.containers.backup,
            observingResults: true
        )
        let backupProfileRepository: ProfileRepository? = nil
#else
        let tunnelStrategy = appConfiguration.newNETunnelStrategy(ctx, coder: registry)
        let mainProfileRepository = NEProfileRepository(repository: tunnelStrategy)
        let backupProfileRepository = appConfiguration.newBackupProfileRepository(
            encoder: appEncoder,
            model: cdRemoteModel,
            name: appConfiguration.constants.containers.backup,
            observingResults: false
        )
#endif
        let profileProcessor = appConfiguration.newAppProfileProcessor(
            iapManager: iapManager
        )
        let profileManager = ProfileManager(
            processor: profileProcessor,
            repository: mainProfileRepository,
            backupRepository: backupProfileRepository,
            mirrorsRemoteRepository: false
        )
        let tunnel = Tunnel(
            ctx,
            strategy: tunnelStrategy,
            refreshInterval: Int(appConfiguration.constants.tunnel.refreshInterval * 1000.0),
            environmentFactory: { @Sendable in
                appConfiguration.newAppTunnelEnvironment(strategy: tunnelStrategy, profileId: $0)
            }
        )

        // Provide hooks through observable
        let logging = TunnelObservable.Logging(
            maxDebugLogLevel: appConfiguration.constants.log.options.maxDebugLogLevel,
            sinceLast: appConfiguration.constants.log.sinceLast,
            formatter: logFormatter
        )
        let tunnelObservable = TunnelObservable(
            tunnel: tunnel,
            preferences: preferences,
            logging: logging,
            willInstall: tunnelProcessor.willInstall
        )

        // MARK: Preferences (Core Data)

        let preferencesManager = PreferencesManager()

        // MARK: Version (GitHub)

        let versionChecker = appConfiguration.newVersionChecker(
            preferences: preferences,
            downloadURL: {
                switch appConfiguration.bundle.distributionTarget {
                case .appStore:
                    return appConfiguration.constants.websites.appStoreDownloadURL
                case .developerID:
                    return appConfiguration.constants.websites.macDownloadURL
                case .enterprise:
                    fatalError("No URL for enterprise distribution")
                }
            }(),
            fetcher: {
                try await appConfiguration.newRequest(
                    for: $0,
                    cached: true,
                    bindings: nil
                )
            }
        )

        // MARK: Web (NIO)

        let webReceiverManager: WebReceiverManager
#if os(tvOS)
        if let webHTMLPath, let webStringsBundle {
            webReceiverManager = appConfiguration.newWebReceiverManager(
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
        let onEligibleFeaturesBlock: @Sendable @BusinessActor (Set<ABI.AppFeature>) async -> Void = { features in
            let isRemoteImportingEnabled = features.contains(.sharing)

            // Toggle CloudKit sync based on .sharing eligibility
            let remoteStore = newRemoteStore(isRemoteImportingEnabled)

            if appConfiguration.bundle.distributionTarget.supportsCloudKit {
                // @Published
                profileManager.enableRemoteImporting(isRemoteImportingEnabled)

                let isCloudKitEnabled = withUITesting || appConfiguration.isCloudKitEnabled
                pspLog(.abi, .info, "\tRefresh remote sync (eligible=\(isRemoteImportingEnabled), CloudKit=\(isCloudKitEnabled))...")
                pspLog(.profiles, .info, "\tRefresh remote profiles repository (sync=\(isRemoteImportingEnabled))...")

                let remoteProfileRepository = CommonData.cdProfileRepositoryV3(
                    encoder: appEncoder,
                    context: remoteStore.context,
                    observingResults: true,
                    onResultError: {
                        pspLog(.profiles, .error, "Unable to decode remote profile: \($0)")
                        return .ignore
                    }
                )
                do {
                    try await profileManager.observeRemote(repository: remoteProfileRepository)
                } catch {
                    pspLog(.profiles, .error, "\tUnable to re-observe remote profiles: \(error)")
                }
            }

            pspLog(.abi, .info, "\tRefresh modules preferences repository...")
            preferencesManager.modulesRepositoryFactory = {
                do {
                    return try CommonData.cdModulePreferencesRepositoryV3(
                        context: remoteStore.context,
                        moduleId: $0
                    )
                } catch {
                    pspLog(.abi, .error, "Unable to load preferences for module \($0): \(error)")
                    throw error
                }
            }

            pspLog(.abi, .info, "\tRefresh providers preferences repository...")
            preferencesManager.providersRepositoryFactory = {
                do {
                    return try CommonData.cdProviderPreferencesRepositoryV3(
                        context: remoteStore.context,
                        providerId: $0
                    )
                } catch {
                    pspLog(.abi, .error, "Unable to load preferences for provider \($0): \(error)")
                    throw error
                }
            }
        }

        let abi = AppABI(
            apiManager: apiManager,
            appConfiguration: appConfiguration,
            appEncoder: appEncoder,
            configManager: configManager,
            extensionInstaller: sysexManager,
            iapManager: iapManager,
            logFormatter: logFormatter,
            preferences: preferences,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager,
            onEligibleFeaturesBlock: onEligibleFeaturesBlock,
            bindings: nil
        )
        return Result(abi: abi, tunnelObservable: tunnelObservable)
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
        encoder: AppEncoder,
        model: NSManagedObjectModel,
        name: String,
        observingResults: Bool
    ) -> ProfileRepository {
        let store = CoreDataPersistentStore(
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
                pspLog(.profiles, .error, "Unable to decode local profile: \($0)")
                return .ignore
            }
        )
    }

    func newInAppFakeHelper() -> FakeInAppHelper {
        FakeInAppHelper()
    }
}
#endif
