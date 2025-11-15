// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibrary
import CommonData
import CommonDataPreferences
import CommonDataProfiles
import CommonDataProviders
import CommonLibrary
import CommonResources
import CoreData
import Foundation
import Partout

extension AppContext {
    convenience init() {

        // MARK: Declare globals

        let distributionTarget = Dependencies.distributionTarget
        let constants = Resources.constants
        let dependencies: Dependencies = .shared
        let loggerStrategy = PartoutLoggerStrategy()
        let kvManager = dependencies.kvManager

        let logURL = BundleConfiguration.urlForAppLog
        let versionString = BundleConfiguration.mainVersionString
        let ctx = PartoutLogger.register(
            for: .app,
            loggingTo: logURL,
            with: kvManager.preferences,
            parameters: constants.log,
            versionString: versionString
        )

        // MARK: Core Data

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
            logger: dependencies.coreDataLogger(),
            containerName: constants.containers.local,
            model: cdLocalModel,
            cloudKitIdentifier: nil,
            author: nil
        )
        let newRemoteStore: (_ cloudKit: Bool) -> CoreDataPersistentStore = { isEnabled in
            let cloudKitIdentifier: String?
            if isEnabled && distributionTarget.supportsCloudKit {
                cloudKitIdentifier = BundleConfiguration.mainString(for: .cloudKitId)
            } else {
                cloudKitIdentifier = nil
            }
            return CoreDataPersistentStore(
                logger: dependencies.coreDataLogger(),
                containerName: constants.containers.remote,
                model: cdRemoteModel,
                cloudKitIdentifier: cloudKitIdentifier,
                author: nil
            )
        }

        // MARK: API/IAP

        let apiManager: APIManager = {
            let repository = CommonData.cdAPIRepositoryV3(context: localStore.backgroundContext())
            return APIManager(ctx, from: API.shared, repository: repository)
        }()
        let iapManager = IAPManager(
            customUserLevel: dependencies.customUserLevel,
            inAppHelper: dependencies.simulatedAppProductHelper(),
            receiptReader: dependencies.simulatedAppReceiptReader(),
            betaChecker: dependencies.betaChecker(),
            timeoutInterval: constants.iap.productsTimeoutInterval,
            productsAtBuild: dependencies.productsAtBuild()
        )
        if distributionTarget.supportsIAP {
            iapManager.isEnabled = !kvManager.bool(forAppPreference: .skipsPurchases)
        } else {
            iapManager.isEnabled = false
        }

        // MARK: Config

#if DEBUG
        let configURL = Bundle.main.url(forResource: "test-bundle", withExtension: "json")!
#else
        let configURL = constants.websites.config
#endif
        let betaConfigURL = constants.websites.betaConfig
        let configManager = ConfigManager(
            strategy: GitHubConfigStrategy(
                url: configURL,
                betaURL: betaConfigURL,
                ttl: constants.websites.configTTL,
                isBeta: { [weak iapManager] in
                    iapManager?.isBeta == true
                }
            ),
            buildNumber: BundleConfiguration.mainBuildNumber
        )

        // MARK: Registry

        let deviceId = {
            if let existingId = kvManager.string(forAppPreference: .deviceId) {
                pp_log_g(.App.core, .info, "Device ID: \(existingId)")
                return existingId
            }
            let newId = String.random(count: constants.deviceIdLength)
            kvManager.set(newId, forAppPreference: .deviceId)
            pp_log_g(.App.core, .info, "Device ID (new): \(newId)")
            return newId
        }()
        let registry = dependencies.newRegistry(
            distributionTarget: distributionTarget,
            deviceId: deviceId,
            configBlock: { [weak configManager, weak kvManager] in
                guard let configManager, let kvManager else { return [] }
                return MainActor.sync {
                    kvManager.preferences.enabledFlags(of: configManager.activeFlags)
                }
            }
        )
        let appEncoder = AppEncoder(registry: registry)

        let tunnelIdentifier = BundleConfiguration.mainString(for: .tunnelId)
#if targetEnvironment(simulator)
        let tunnelStrategy = FakeTunnelStrategy()
        let mainProfileRepository = dependencies.backupProfileRepository(
            ctx,
            encoder: appEncoder,
            model: cdRemoteModel,
            name: constants.containers.backup,
            observingResults: true
        )
        let backupProfileRepository: ProfileRepository? = nil
#else
        let tunnelStrategy = NETunnelStrategy(
            ctx,
            bundleIdentifier: tunnelIdentifier,
            coder: dependencies.neProtocolCoder(ctx, registry: registry)
        )
        let mainProfileRepository = NEProfileRepository(repository: tunnelStrategy) {
            dependencies.profileTitle($0)
        }
        let backupProfileRepository = dependencies.backupProfileRepository(
            ctx,
            encoder: appEncoder,
            model: cdRemoteModel,
            name: constants.containers.backup,
            observingResults: false
        )
#endif

        let processor = dependencies.appProcessor(
            apiManager: apiManager,
            iapManager: iapManager,
            registry: registry
        )
        let profileManager = ProfileManager(
            registry: registry,
            processor: processor,
            repository: mainProfileRepository,
            backupRepository: backupProfileRepository,
            mirrorsRemoteRepository: dependencies.mirrorsRemoteRepository
        )

        let sysexManager: SystemExtensionManager?
        if distributionTarget == .developerID {
            sysexManager = SystemExtensionManager(
                identifier: tunnelIdentifier,
                version: BundleConfiguration.mainVersionNumber,
                build: BundleConfiguration.mainBuildNumber
            )
        } else {
            sysexManager = nil
        }
        let tunnel = ExtendedTunnel(
            tunnel: Tunnel(ctx, strategy: tunnelStrategy) {
                dependencies.appTunnelEnvironment(strategy: tunnelStrategy, profileId: $0)
            },
            sysex: sysexManager,
            kvManager: kvManager,
            processor: processor,
            interval: constants.tunnel.refreshInterval
        )

        let onboardingManager = OnboardingManager(kvManager: kvManager)
        let preferencesManager = PreferencesManager()

#if os(tvOS)
        let webReceiver = NIOWebReceiver(
            logger: loggerStrategy,
            htmlPath: Resources.webUploaderPath,
            stringsBundle: AppStrings.bundle,
            port: constants.webReceiver.port
        )
        let webReceiverManager = WebReceiverManager(webReceiver: webReceiver) {
            dependencies.webPasscodeGenerator(length: constants.webReceiver.passcodeLength)
        }
#else
        let webReceiverManager = WebReceiverManager()
#endif

        // MARK: Eligibility

        let onEligibleFeaturesBlock: (Set<AppFeature>) async -> Void = { @MainActor features in
            let isEligibleForSharing = features.contains(.sharing)
            let isRemoteImportingEnabled = isEligibleForSharing

            // toggle CloudKit sync based on .sharing eligibility
            let remoteStore = newRemoteStore(isRemoteImportingEnabled)

            if distributionTarget.supportsCloudKit {

                // @Published
                profileManager.isRemoteImportingEnabled = isRemoteImportingEnabled

                do {
                    pp_log(ctx, .App.core, .info, "\tRefresh remote sync (eligible=\(isEligibleForSharing), CloudKit=\(dependencies.isCloudKitEnabled))...")

                    pp_log(ctx, .App.profiles, .info, "\tRefresh remote profiles repository (sync=\(isRemoteImportingEnabled))...")
                    try await profileManager.observeRemote(repository: {
                        CommonData.cdProfileRepositoryV3(
                            encoder: appEncoder,
                            context: remoteStore.context,
                            observingResults: true,
                            onResultError: {
                                pp_log(ctx, .App.profiles, .error, "Unable to decode remote profile: \($0)")
                                return .ignore
                            }
                        )
                    }())
                } catch {
                    pp_log(ctx, .App.profiles, .error, "\tUnable to re-observe remote profiles: \(error)")
                }
            }

            pp_log(ctx, .App.core, .info, "\tRefresh modules preferences repository...")
            preferencesManager.modulesRepositoryFactory = {
                try CommonData.cdModulePreferencesRepositoryV3(
                    context: remoteStore.context,
                    moduleId: $0
                )
            }

            pp_log(ctx, .App.core, .info, "\tRefresh providers preferences repository...")
            preferencesManager.providersRepositoryFactory = {
                try CommonData.cdProviderPreferencesRepositoryV3(
                    context: remoteStore.context,
                    providerId: $0
                )
            }

            pp_log(ctx, .App.profiles, .info, "\tReload profiles required features...")
            profileManager.reloadRequiredFeatures()
        }

        // MARK: Version

        let versionStrategy = GitHubReleaseStrategy(
            releaseURL: constants.github.latestRelease,
            rateLimit: constants.api.versionRateLimit
        )
        let versionChecker: VersionChecker
        if !iapManager.isBeta {
            versionChecker = VersionChecker(
                kvManager: kvManager,
                strategy: versionStrategy,
                currentVersion: BundleConfiguration.mainVersionNumber,
                downloadURL: {
                    switch distributionTarget {
                    case .appStore:
                        return constants.websites.appStoreDownload
                    case .developerID:
                        return constants.websites.macDownload
                    case .enterprise:
                        fatalError("No URL for enterprise distribution")
                    }
                }()
            )
        } else {
            versionChecker = VersionChecker()
        }

        // MARK: Build

        self.init(
            apiManager: apiManager,
            appEncoder: appEncoder,
            configManager: configManager,
            distributionTarget: distributionTarget,
            iapManager: iapManager,
            kvManager: kvManager,
            loggerStrategy: loggerStrategy,
            onboardingManager: onboardingManager,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            sysexManager: sysexManager,
            tunnel: tunnel,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager,
            receiptInvalidationInterval: constants.iap.receiptInvalidationInterval,
            onEligibleFeaturesBlock: onEligibleFeaturesBlock
        )
    }
}

// MARK: - Dependencies

private extension Dependencies {
    var isCloudKitEnabled: Bool {
#if os(tvOS)
        true
#else
        if AppCommandLine.contains(.uiTesting) {
            return true
        }
        return FileManager.default.ubiquityIdentityToken != nil
#endif
    }

    func simulatedAppProductHelper() -> any AppProductHelper {
        if AppCommandLine.contains(.fakeIAP) {
            return FakeAppProductHelper()
        }
        return appProductHelper()
    }

    func simulatedAppReceiptReader() -> AppReceiptReader {
        if AppCommandLine.contains(.fakeIAP) {
            guard let mockHelper = simulatedAppProductHelper() as? FakeAppProductHelper else {
                fatalError("When .isFakeIAP, simulatedInAppHelper is expected to be MockAppProductHelper")
            }
            return mockHelper.receiptReader
        }
        return SharedReceiptReader(
            reader: StoreKitReceiptReader(logger: iapLogger())
        )
    }

    var mirrorsRemoteRepository: Bool {
        false
    }

    func backupProfileRepository(
        _ ctx: PartoutLoggerContext,
        encoder: AppEncoder,
        model: NSManagedObjectModel,
        name: String,
        observingResults: Bool
    ) -> ProfileRepository {
        let store = CoreDataPersistentStore(
            logger: coreDataLogger(),
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
                pp_log(ctx, .App.profiles, .error, "Unable to decode local profile: \($0)")
                return .ignore
            }
        )
    }

    func webPasscodeGenerator(length: Int) -> String {
        let upperBound = Int(pow(10, Double(length)))
        return String(format: "%0\(length)d", Int.random(in: 0..<upperBound))
    }
}
