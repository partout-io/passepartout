// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibrary
import AppResources
import CommonData
import CommonDataPreferences
import CommonDataProfiles
import CommonDataProviders
import CommonLibrary
import CoreData
import Partout

extension AppContext {
    static func forProduction(bundleIdentifier: String) -> AppContext {
        let distributionTarget: ABI.DistributionTarget
#if PP_BUILD_MAC
        distributionTarget = .developerID
#else
        distributionTarget = .appStore
#endif
        let appConfiguration = Resources.newAppConfiguration(
            distributionTarget: distributionTarget,
            buildTarget: .app
        )
        let defaults: UserDefaults = .standard
        let preferences = AppPreferencesStore(
            UserDefaultsAppPreferences(defaults: defaults)
        )
        let deviceId = preferences.configureDeviceId(
            length: appConfiguration.constants.deviceIdLength
        )

        let logFormatter = appConfiguration.makeLogFormatter()
        let ctx = pspLogRegister(
            for: .app,
            with: appConfiguration,
            preferences: preferences,
            localURL: appConfiguration.urlForAppLog,
            localMapper: logFormatter.localMapper
        )
        pspLog(.core, .notice, "Partout \(PartoutConstants.version)")

        // MARK: Config (GitHub)

        let betaChecker = appConfiguration.makeBetaChecker()
#if DEBUG
        let withTestBundle = true
#else
        let withTestBundle = false
#endif
        let configManager = appConfiguration.makeConfigManager(
            withTestBundle: withTestBundle,
            isBeta: {
                await betaChecker.isBeta()
            },
            fetcher: {
                try await appConfiguration.makeRequest(for: $0, cached: false)
            }
        )

        // MARK: Registry

        let cachesURL = FileManager.default.temporaryDirectory
        let registry = appConfiguration.makeRegistryForApp(
            deviceId: deviceId,
            preferences: preferences,
            configManager: configManager,
            cachesURL: cachesURL
        )

        // Ensure that all module builders can be rendered in the profile editor.
        ModuleType.knownTypes.forEach { moduleType in
#if !os(tvOS)
            let builder = registry.newModule(ofType: moduleType)
            assert(builder is any ModuleViewProviding, "\(moduleType): is not ModuleViewProviding")
#endif
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
        if !AppCommandLine.contains(.fakeIAP) {
            iapHelper = appConfiguration.makeInAppHelper()
            iapReceiptReader = SharedReceiptReader(
                reader: appConfiguration.makeInAppReceiptReader {
                    // TODO: #1786, StoreKit receipt caching
                    .uncached
                }
            )
        } else {
            let fakeHelper = FakeInAppHelper()
            iapHelper = fakeHelper
            iapReceiptReader = fakeHelper.receiptReader
        }
        let iapManager = appConfiguration.makeIAPManager(
            inAppHelper: iapHelper,
            receiptReader: iapReceiptReader,
            betaChecker: betaChecker
        )

        // MARK: API

        let apiManager = APIManager(
            from: API.shared,
            repository: CommonData.cdAPIRepositoryV3(
                context: localStore.backgroundContext()
            )
        )

        // MARK: Profiles and Tunnel (NE)

        let sysexManager = appConfiguration.makeSystemExtensionManager()
        let appEncoder = AppEncoder(coder: registry)
        let tunnelProcessor = appConfiguration.makeAppTunnelProcessor(
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
        let codingPair = appConfiguration.makeKeychainAndNECoder(
            ctx,
            bundleIdentifier: bundleIdentifier,
            coder: registry
        )
        let profilesBootstrap: KeychainProfileRepository.Bootstrap?

        // Plan a one-off migration for Developer ID profiles
        if distributionTarget == .developerID {
            let tunnelIdentifier = appConfiguration.bundle.bundleString(for: .tunnelId)
            let marker = MigrationMarker(defaults: defaults)
            let migrator = NEManagerToKeychainMigrator(
                tunnelBundleIdentifier: tunnelIdentifier,
                keychain: codingPair.keychain,
                profileCoder: registry,
                protocolCoder: codingPair.neCoder,
                label: appConfiguration.makeKeychainTitle(),
                isComplete: {
                    marker.isComplete(.didMigrateDeveloperIDManagers)
                },
                markComplete: {
                    marker.markComplete(.didMigrateDeveloperIDManagers)
                }
            )
            profilesBootstrap = { @Sendable in
                await migrator.run()
            }
        } else {
            profilesBootstrap = nil
        }

        let mainProfileRepository = KeychainProfileRepository(
            keychain: codingPair.keychain,
            coder: registry,
            bootstrap: profilesBootstrap,
            label: appConfiguration.makeKeychainTitle()
        )
        let tunnelStrategy = appConfiguration.makeNETunnelStrategy(
            ctx,
            coder: codingPair.neCoder,
            source: mainProfileRepository.eventsPublisher
        )
        let backupProfileRepository = appConfiguration.newBackupProfileRepository(
            encoder: appEncoder,
            model: cdRemoteModel,
            name: appConfiguration.constants.containers.backup,
            observingResults: false
        )
#endif
        let profileProcessor = appConfiguration.makeAppProfileProcessor(
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
                appConfiguration.makeAppTunnelEnvironment(strategy: tunnelStrategy, profileId: $0)
            }
        )

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

        let versionChecker = appConfiguration.makeVersionChecker(
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
                try await appConfiguration.makeRequest(for: $0, cached: $1)
            }
        )

        // MARK: Web (NIO)

        let webReceiverManager: WebReceiverManager
#if os(tvOS)
        if let webHTMLPath = Resources.webUploaderPath {
            webReceiverManager = appConfiguration.makeWebReceiverManager(
                htmlPath: webHTMLPath,
                stringsBundle: AppStrings.bundle
            )
        } else {
            webReceiverManager = WebReceiverManager()
        }
#else
        webReceiverManager = WebReceiverManager()
#endif

        // MARK: Sync (CloudKit)

        // Remote profiles and preferences are (re)created on synchronization updates.
        let onEligibleFeaturesBlock: @Sendable @BusinessActor (Set<ABI.AppFeature>) async -> Void = { features in
            let isRemoteImportingEnabled = features.contains(.sharing)
            let remoteStore = newRemoteStore(isRemoteImportingEnabled)

            if appConfiguration.bundle.distributionTarget.supportsCloudKit {
                profileManager.enableRemoteImporting(isRemoteImportingEnabled)

                let isCloudKitEnabled = AppCommandLine.contains(.uiTesting) || appConfiguration.isCloudKitEnabled
                pspLog(.core, .info, "\tRefresh remote sync (eligible=\(isRemoteImportingEnabled), CloudKit=\(isCloudKitEnabled))...")
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

            pspLog(.core, .info, "\tRefresh modules preferences repository...")
            preferencesManager.modulesRepositoryFactory = {
                do {
                    return try CommonData.cdModulePreferencesRepositoryV3(
                        context: remoteStore.context,
                        moduleId: $0
                    )
                } catch {
                    pspLog(.core, .error, "Unable to load preferences for module \($0): \(error)")
                    throw error
                }
            }

            pspLog(.core, .info, "\tRefresh providers preferences repository...")
            preferencesManager.providersRepositoryFactory = {
                do {
                    return try CommonData.cdProviderPreferencesRepositoryV3(
                        context: remoteStore.context,
                        providerId: $0
                    )
                } catch {
                    pspLog(.core, .error, "Unable to load preferences for provider \($0): \(error)")
                    throw error
                }
            }
        }

        return AppContext(
            apiManager: apiManager,
            appConfiguration: appConfiguration,
            appEncoder: appEncoder,
            configManager: configManager,
            defaults: defaults,
            extensionInstaller: sysexManager,
            iapManager: iapManager,
            preferences: preferences,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            tunnelObservable: tunnelObservable,
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
}
