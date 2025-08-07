// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibrary
import CommonData
import CommonDataPreferences
import CommonDataProfiles
import CommonDataProviders
import CommonLegacyV2
import CommonLibrary
import CommonUtils
#if os(tvOS)
import CommonWeb
#endif
import CoreData
import Foundation

extension AppContext {
    convenience init() {

        // MARK: Declare globals

        let dependencies: Dependencies = .shared
        let distributionTarget = Dependencies.distributionTarget
        let constants: Constants = .shared
        let kvManager = dependencies.kvManager

        let ctx = PartoutLogger.register(for: .app, with: kvManager.preferences)

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

        // MARK: Registry

        let deviceId = {
            if let existingId = kvManager.string(forKey: AppPreference.deviceId.key) {
                pp_log_g(.app, .info, "Device ID: \(existingId)")
                return existingId
            }
            let newId = String.random(count: Constants.shared.deviceIdLength)
            kvManager.set(newId, forKey: AppPreference.deviceId.key)
            pp_log_g(.app, .info, "Device ID (new): \(newId)")
            return newId
        }()

        let registry = dependencies.newRegistry(
            distributionTarget: distributionTarget,
            deviceId: deviceId
        )
        let registryCoder = registry.with(coder: dependencies.sharedProfileCoder)

        // MARK: Managers

        let apiManager: APIManager = {
            let repository = CommonData.cdAPIRepositoryV3(context: localStore.backgroundContext())
            return APIManager(ctx, from: API.shared, repository: repository)
        }()
        let iapManager = IAPManager(
            customUserLevel: dependencies.customUserLevel,
            inAppHelper: dependencies.simulatedAppProductHelper(),
            receiptReader: dependencies.simulatedAppReceiptReader(),
            betaChecker: dependencies.betaChecker(),
            productsAtBuild: dependencies.productsAtBuild()
        )
        if distributionTarget.supportsIAP {
            iapManager.isEnabled = !kvManager.bool(forKey: AppPreference.skipsPurchases.key)
        } else {
            iapManager.isEnabled = false
        }
        let processor = dependencies.appProcessor(
            apiManager: apiManager,
            iapManager: iapManager,
            registry: registry
        )

        let tunnelIdentifier = BundleConfiguration.mainString(for: .tunnelId)
#if targetEnvironment(simulator)
        let tunnelStrategy = FakeTunnelStrategy()
        let mainProfileRepository = dependencies.backupProfileRepository(
            ctx,
            registryCoder: registryCoder,
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
            registryCoder: registryCoder,
            model: cdRemoteModel,
            name: constants.containers.backup,
            observingResults: false
        )
#endif

        let profileManager = ProfileManager(
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

        let migrationManager: MigrationManager
        if distributionTarget.supportsV2Migration {
            migrationManager = {
                let profileStrategy = ProfileV2MigrationStrategy(
                    coreDataLogger: dependencies.coreDataLogger(),
                    profilesContainer: .init(
                        constants.containers.legacyV2,
                        BundleConfiguration.mainString(for: .legacyV2CloudKitId)
                    ),
                    tvProfilesContainer: .init(
                        constants.containers.legacyV2TV,
                        BundleConfiguration.mainString(for: .legacyV2TVCloudKitId)
                    )
                )
                let migrationSimulation: MigrationManager.Simulation?
                if AppCommandLine.contains(.fakeMigration) {
                    migrationSimulation = MigrationManager.Simulation(
                        fakeProfiles: true,
                        maxMigrationTime: 3.0,
                        randomFailures: true
                    )
                } else {
                    migrationSimulation = nil
                }
                return MigrationManager(profileStrategy: profileStrategy, simulation: migrationSimulation)
            }()
        } else {
            migrationManager = MigrationManager()
        }

        let onboardingManager = OnboardingManager(kvManager: kvManager)
        let preferencesManager = PreferencesManager()

#if os(tvOS)
        let webReceiver = NIOWebReceiver(stringsBundle: AppStrings.bundle, port: constants.webReceiver.port)
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
                    pp_log(ctx, .app, .info, "\tRefresh remote sync (eligible=\(isEligibleForSharing), CloudKit=\(dependencies.isCloudKitEnabled))...")

                    pp_log(ctx, .App.profiles, .info, "\tRefresh remote profiles repository (sync=\(isRemoteImportingEnabled))...")
                    try await profileManager.observeRemote(repository: {
                        CommonData.cdProfileRepositoryV3(
                            registryCoder: registryCoder,
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

            pp_log(ctx, .app, .info, "\tRefresh modules preferences repository...")
            preferencesManager.modulesRepositoryFactory = {
                try CommonData.cdModulePreferencesRepositoryV3(
                    context: remoteStore.context,
                    moduleId: $0
                )
            }

            pp_log(ctx, .app, .info, "\tRefresh providers preferences repository...")
            preferencesManager.providersRepositoryFactory = {
                try CommonData.cdProviderPreferencesRepositoryV3(
                    context: remoteStore.context,
                    providerId: $0
                )
            }

            pp_log(ctx, .App.profiles, .info, "\tReload profiles required features...")
            profileManager.reloadRequiredFeatures()
        }

        // MARK: Config

#if DEBUG
        let configURL = Bundle.main.url(forResource: "test-bundle", withExtension: "json")!
        let betaConfigURL = configURL
#else
        let configURL = Constants.shared.websites.config
        let betaConfigURL = Constants.shared.websites.betaConfig
#endif
        let configManager = ConfigManager(
            strategy: GitHubConfigStrategy(
                url: configURL,
                betaURL: betaConfigURL,
                ttl: Constants.shared.websites.configTTL,
                isBeta: { [weak iapManager] in
                    iapManager?.isBeta == true
                }
            )
        )

        // MARK: Version

        let versionStrategy = GitHubReleaseStrategy(
            releaseURL: Constants.shared.github.latestRelease,
            rateLimit: Constants.shared.api.versionRateLimit
        )
        let versionChecker = VersionChecker(
            kvManager: kvManager,
            strategy: versionStrategy,
            currentVersion: BundleConfiguration.mainVersionNumber,
            downloadURL: {
                switch distributionTarget {
                case .appStore:
                    return Constants.shared.websites.appStoreDownload
                case .developerID:
                    return Constants.shared.websites.macDownload
                case .enterprise:
                    fatalError("No URL for enterprise distribution")
                }
            }()
        )

        // MARK: Build

        self.init(
            apiManager: apiManager,
            configManager: configManager,
            distributionTarget: distributionTarget,
            iapManager: iapManager,
            kvManager: kvManager,
            migrationManager: migrationManager,
            onboardingManager: onboardingManager,
            preferencesManager: preferencesManager,
            profileCoder: dependencies.sharedProfileCoder,
            profileManager: profileManager,
            registry: registry,
            sysexManager: sysexManager,
            tunnel: tunnel,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager,
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
        registryCoder: RegistryCoder,
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
            registryCoder: registryCoder,
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
