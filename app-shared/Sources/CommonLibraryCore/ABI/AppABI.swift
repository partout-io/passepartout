// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Drop import (do not expose Partout to UI)
import Partout

@MainActor
public final class AppABI: Sendable {
    // MARK: Business

    public let config: AppABIConfigProtocol
    public let encoder: AppABIEncoderProtocol
    public let iap: AppABIIAPProtocol
    public let profile: AppABIProfileProtocol
    public let registry: AppABIRegistryProtocol
    public let tunnel: AppABITunnelProtocol
    public let version: AppABIVersionProtocol
    public let webReceiver: AppABIWebReceiverProtocol
    private let onEligibleFeaturesBlock: ((Set<ABI.AppFeature>) async -> Void)?

    // FIXME: #1594, Drop these after observables
    @available(*, deprecated, message: "#1594")
    public let apiManager: APIManager
    @available(*, deprecated, message: "#1594")
    public let appEncoder: AppEncoder
    @available(*, deprecated, message: "#1594")
    public let configManager: ConfigManager
    @available(*, deprecated, message: "#1594")
    public let iapManager: IAPManager
    @available(*, deprecated, message: "#1594")
    public let preferencesManager: PreferencesManager
    @available(*, deprecated, message: "#1594")
    public let profileManager: ProfileManager
    @available(*, deprecated, message: "#1594")
    public let partoutRegistry: Registry
    @available(*, deprecated, message: "#1594")
    public let tunnelManager: TunnelManager
    @available(*, deprecated, message: "#1594")
    private let versionChecker: VersionChecker
    @available(*, deprecated, message: "#1594")
    public let webReceiverManager: WebReceiverManager

    // MARK: Internal state

    private let appConfiguration: ABI.AppConfiguration
    private let extensionInstaller: ExtensionInstaller?
    private let kvStore: KeyValueStore
    private let logFormatter: LogFormatter

    private var launchTask: Task<Void, Error>?
    private var pendingTask: Task<Void, Never>?
    private var didLoadReceiptDate: Date?
    private var subscriptions: [Task<Void, Never>]

    public init(
        apiManager: APIManager,
        appConfiguration: ABI.AppConfiguration,
        appEncoder: AppEncoder,
        configManager: ConfigManager,
        extensionInstaller: ExtensionInstaller?,
        iapManager: IAPManager,
        kvStore: KeyValueStore,
        logFormatter: LogFormatter,
        preferencesManager: PreferencesManager,
        profileManager: ProfileManager,
        registry partoutRegistry: Registry,
        tunnelManager: TunnelManager,
        versionChecker: VersionChecker,
        webReceiverManager: WebReceiverManager,
        onEligibleFeaturesBlock: ((Set<ABI.AppFeature>) async -> Void)? = nil
    ) {
        self.apiManager = apiManager
        self.appConfiguration = appConfiguration
        self.appEncoder = appEncoder
        self.configManager = configManager
        self.extensionInstaller = extensionInstaller
        self.iapManager = iapManager
        self.kvStore = kvStore
        self.logFormatter = logFormatter
        self.preferencesManager = preferencesManager
        self.profileManager = profileManager
        self.partoutRegistry = partoutRegistry
        self.tunnelManager = tunnelManager
        self.versionChecker = versionChecker
        self.webReceiverManager = webReceiverManager
        self.onEligibleFeaturesBlock = onEligibleFeaturesBlock
        subscriptions = []

        iapManager.isEnabled = appConfiguration.distributionTarget.supportsIAP && !kvStore.bool(forAppPreference: .skipsPurchases)

        config = AppABIConfig(configManager: configManager)
        encoder = AppABIEncoder(appEncoder: appEncoder)
        iap = AppABIIAP(
            iapManager: iapManager,
            kvStore: kvStore,
            supportsIAP: appConfiguration.distributionTarget.supportsIAP
        )
        profile = AppABIProfile(
            profileManager: profileManager,
            registry: partoutRegistry
        )
        registry = AppABIRegistry(registry: partoutRegistry)
        tunnel = AppABITunnel(
            tunnelManager: tunnelManager,
            logParameters: appConfiguration.constants.log
        )
        version = AppABIVersion(versionChecker: versionChecker)
        webReceiver = AppABIWebReceiver(webReceiverManager: webReceiverManager)
    }

    deinit {
        subscriptions.forEach { $0.cancel() }
    }

    public func registerEvents(
        context: ABI.EventContext?,
        callback: @escaping ABI.EventCallback
    ) {
        let configEvents = configManager.didChange.subscribe()
        let iapEvents = iapManager.didChange.subscribe()
        let profileEvents = profileManager.didChange.subscribe()
        let tunnelEvents = tunnelManager.didChange.subscribe()
        let webReceiverUploads = webReceiverManager.files
        subscriptions.append(Task {
            for await event in configEvents {
                callback(context, .config(event))
            }
        })
        subscriptions.append(Task {
            for await event in iapEvents {
                callback(context, .iap(event))
            }
        })
        subscriptions.append(Task {
            for await event in profileEvents {
                callback(context, .profile(event))
            }
        })
        subscriptions.append(Task {
            for await event in tunnelEvents {
                callback(context, .tunnel(event))
            }
        })
        subscriptions.append(Task {
            for await upload in webReceiverUploads {
                callback(context, .webReceiver(.newUpload(upload)))
            }
        })
    }
}

extension AppABI: AppABILoggerProtocol, LogFormatter {
    public nonisolated func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        pspLog(category, level, message)
    }

    public nonisolated func flushLogs() {
        pspLogFlush()
    }

    public nonisolated func formattedLog(timestamp: Date, message: String) -> String {
        logFormatter.formattedLog(timestamp: timestamp, message: message)
    }
}

// MARK: - Actions

private struct AppABIConfig: AppABIConfigProtocol {
    let configManager: ConfigManager

    var activeFlags: Set<ABI.ConfigFlag> {
        configManager.activeFlags
    }

    func data(for flag: ABI.ConfigFlag) -> JSON? {
        configManager.data(for: flag)
    }
}

private struct AppABIEncoder: AppABIEncoderProtocol {
    let appEncoder: AppEncoder

    func defaultFilename(for profile: ABI.AppProfile) -> String {
        appEncoder.defaultFilename(for: profile.native)
    }

    func profile(fromString string: String) throws -> ABI.AppProfile {
        try ABI.AppProfile(native: appEncoder.profile(fromString: string))
    }

    func json(fromProfile profile: ABI.AppProfile) throws -> String {
        try appEncoder.json(fromProfile: profile.native)
    }

    func writeToFile(_ profile: ABI.AppProfile) throws -> String {
        try appEncoder.writeToFile(profile.native)
    }
}

private struct AppABIIAP: AppABIIAPProtocol {
    let iapManager: IAPManager
    let kvStore: KeyValueStore
    let supportsIAP: Bool

    var isEnabled: Bool {
        iapManager.isEnabled
    }

    func enable(_ isEnabled: Bool) {
        iapManager.isEnabled = supportsIAP && isEnabled
        kvStore.set(!iapManager.isEnabled, forAppPreference: .skipsPurchases)
    }

    func verify(_ profile: ABI.AppProfile, extra: Set<ABI.AppFeature>?) throws {
        try iapManager.verify(profile, extra: extra)
    }

    func purchase(_ storeProduct: ABI.StoreProduct) async throws -> ABI.StoreResult {
        try await iapManager.purchase(storeProduct)
    }

    func reloadReceipt() async {
        await iapManager.reloadReceipt()
    }

    func restorePurchases() async throws {
        try await iapManager.restorePurchases()
    }

    func suggestedProducts(for features: Set<ABI.AppFeature>) -> Set<ABI.AppProduct> {
        iapManager.suggestedProducts(for: features)
    }

    func purchasableProducts(for products: [ABI.AppProduct]) async throws -> [ABI.StoreProduct] {
        try await iapManager.fetchPurchasableProducts(for: products)
    }

    var originalPurchase: ABI.OriginalPurchase? {
        iapManager.originalPurchase
    }

    var purchasedProducts: Set<ABI.AppProduct> {
        iapManager.purchasedProducts
    }

    var isBeta: Bool {
        iapManager.isBeta
    }

    func isEligible(for feature: ABI.AppFeature) -> Bool {
        iapManager.isEligible(for: feature)
    }

    func isEligible(for features: Set<ABI.AppFeature>) -> Bool {
        iapManager.isEligible(for: features)
    }

    var isEligibleForFeedback: Bool {
        iapManager.isEligibleForFeedback
    }

    var isEligibleForComplete: Bool {
        iapManager.isEligibleForComplete
    }

    var verificationDelayMinutes: Int {
        iapManager.verificationDelayMinutes
    }
}

private struct AppABIProfile: AppABIProfileProtocol {
    let profileManager: ProfileManager
    let registry: Registry

    func profile(withId id: ABI.AppIdentifier) -> ABI.AppProfile? {
        profileManager.profile(withId: id)
    }

    func save(_ profile: ABI.AppProfile, remotelyShared: Bool?) async throws {
        try await profileManager.save(profile.native, isLocal: true, remotelyShared: remotelyShared)
    }

    func saveAll() async {
        await profileManager.resaveAllProfiles()
    }

    func importText(_ text: String, filename: String, passphrase: String?) async throws {
        let profile = try registry.importedProfile(
            from: .contents(filename: filename, data: text),
            passphrase: passphrase
        )
        try await profileManager.save(profile, isLocal: true, remotelyShared: nil)
    }

    func importFile(_ path: String, passphrase: String?) async throws {
        let profile = try registry.importedProfile(
            from: .file(URL(fileURLWithPath: path)),
            passphrase: passphrase
        )
        try await profileManager.save(profile, isLocal: true, remotelyShared: nil)
    }

    func duplicate(_ id: ABI.AppIdentifier) async throws {
        try await profileManager.duplicate(profileWithId: id)
    }

    func remove(_ id: ABI.AppIdentifier) async {
        await profileManager.remove(withId: id)
    }

    func remove(_ ids: [ABI.AppIdentifier]) async {
        await profileManager.remove(withIds: ids)
    }

    func removeAllRemote() async throws {
        try await profileManager.eraseRemotelySharedProfiles()
    }

    func isRemotelyShared(_ id: ABI.AppIdentifier) -> Bool {
        profileManager.isRemotelyShared(profileWithId: id)
    }

    var isRemoteImportingEnabled: Bool {
        profileManager.isRemoteImportingEnabled
    }
}

private struct AppABIRegistry: AppABIRegistryProtocol {
    let registry: Registry

    func newModule(ofType type: ModuleType) -> any ModuleBuilder {
        type.newModule(with: registry)
    }

    func validate(_ builder: any ModuleBuilder) throws {
        guard let impl = registry.implementation(for: builder) as? ModuleBuilderValidator else {
            return
        }
        try impl.validate(builder)
    }

    func implementation(for id: ModuleHandler.ID) -> (any ModuleImplementation)? {
        registry.implementation(for: id)
    }

    func resolvedModule(_ module: ProviderModule) throws -> Module {
        try registry.resolvedModule(module, in: nil)
    }
}

private struct AppABITunnel: AppABITunnelProtocol {
    let tunnelManager: TunnelManager
    let logParameters: ABI.Constants.Log

    func connect(to profile: ABI.AppProfile, force: Bool) async throws {
        try await tunnelManager.connect(with: profile.native, force: force)
    }

//    func reconnect(to profileId: ABI.Identifier) async throws {
//        try await tunnel.
//    }

    func disconnect(from profileId: ABI.AppIdentifier) async throws {
        try await tunnelManager.disconnect(from: profileId)
    }

    func currentLog() async -> [ABI.AppLogLine] {
        await tunnelManager.currentLog(parameters: logParameters)
    }

    func lastError(ofProfileId profileId: ABI.AppIdentifier) -> ABI.AppError? {
        tunnelManager.lastError(ofProfileId: profileId)
    }

    func transfer(ofProfileId profileId: ABI.AppIdentifier) -> ABI.ProfileTransfer? {
        tunnelManager.transfer(ofProfileId: profileId)
    }

    func environmentValue(for key: AppABITunnelValueKey, ofProfileId profileId: ABI.AppIdentifier) -> Any? {
        switch key {
        case .openVPNServerConfiguration:
            tunnelManager.value(
                forKey: TunnelEnvironmentKeys.OpenVPN.serverConfiguration,
                ofProfileId: profileId
            )
        }
    }
}

private struct AppABIVersion: AppABIVersionProtocol {
    let versionChecker: VersionChecker

    func checkLatestRelease() async {
        await versionChecker.checkLatestRelease()
    }

    var latestRelease: ABI.VersionRelease? {
        versionChecker.latestRelease
    }
}

private struct AppABIWebReceiver: AppABIWebReceiverProtocol {
    let webReceiverManager: WebReceiverManager

    func start() throws {
        try webReceiverManager.start()
    }

    func stop() {
        webReceiverManager.stop()
    }

    func refresh() {
        webReceiverManager.renewPasscode()
    }

    var isStarted: Bool {
        webReceiverManager.isStarted
    }

    var website: ABI.WebsiteWithPasscode? {
        webReceiverManager.website
    }
}

// MARK: - Observation

// Invoked by AppDelegate
extension AppABI {
    public func onApplicationActive() {
        Task {
            // XXX: Should handle ABI.AppError.couldNotLaunch (although extremely rare)
            try await onForeground()

            await configManager.refreshBundle()
            await versionChecker.checkLatestRelease()

            // Propagate active config flags to tunnel via preferences
            kvStore.preferences.configFlags = configManager.activeFlags

            // Disable .relaxedVerification if ABI.ConfigFlag disallows it
            if !configManager.isActive(.allowsRelaxedVerification) {
                kvStore.set(false, forAppPreference: .relaxedVerification)
            }
        }
    }
}

// Invoked on internal events
private extension AppABI {
    func onLaunch() async throws {
        pspLog(.core, .notice, "Application did launch")

        pspLog(.profiles, .info, "\tRead and observe local profiles...")
        try await profileManager.observeLocal()

        pspLog(.profiles, .info, "\tObserve in-app events...")
        iapManager.observeObjects(withProducts: true)

        // Defer loads to not block app launch
        Task {
            await iapManager.reloadReceipt()
            didLoadReceiptDate = Date()
        }
        Task {
            await reloadExtensions()
        }

        pspLog(.iap, .info, "\tObserve changes in IAPManager...")
        let iapEvents = iapManager.didChange.subscribe()
        subscriptions.append(Task { [weak self] in
            guard let self else { return }
            for await event in iapEvents {
                switch event {
                case .status(let isEnabled):
                    // FIXME: #1594, .dropFirst() + .removeDuplicates()
                    pspLog(.iap, .info, "IAPManager.isEnabled -> \(isEnabled)")
                    kvStore.set(!isEnabled, forAppPreference: .skipsPurchases)
                    await iapManager.reloadReceipt()
                    didLoadReceiptDate = Date()
                case .eligibleFeatures(let features):
                    // FIXME: #1594, .dropFirst() + .removeDuplicates()
                    do {
                        pspLog(.iap, .info, "IAPManager.eligibleFeatures -> \(features)")
                        try await onEligibleFeatures(features)
                    } catch {
                        pspLog(.iap, .error, "Unable to react to eligible features: \(error)")
                    }
                default:
                    break
                }
            }
        })

        pspLog(.profiles, .info, "\tObserve changes in ProfileManager...")
        let profileEvents = profileManager.didChange.subscribe()
        subscriptions.append(Task { [weak self] in
            guard let self else { return }
            for await event in profileEvents {
                switch event {
                case .save(let profile, let previousProfile):
                    do {
                        try await onSaveProfile(profile, previous: previousProfile)
                    } catch {
                        pspLog(.profiles, .error, "Unable to react to saved profile: \(error)")
                    }
                default:
                    break
                }
            }
        })

        do {
            pspLog(.core, .info, "\tFetch providers index...")
            try await apiManager.fetchIndex()
        } catch {
            pspLog(.core, .error, "\tUnable to fetch providers index: \(error)")
        }
    }

    func onForeground() async throws {

        // onForeground() is redundant after launch
        let didLaunch = try await waitForTasks()
        guard !didLaunch else {
            return
        }

        pspLog(.core, .notice, "Application did enter foreground")
        pendingTask = Task {
            await reloadExtensions()

            // Do not reload the receipt unconditionally
            if shouldInvalidateReceipt {
                await iapManager.reloadReceipt()
                self.didLoadReceiptDate = Date()
            }
        }
        await pendingTask?.value
        pendingTask = nil
    }

    func onEligibleFeatures(_ features: Set<ABI.AppFeature>) async throws {
        try await waitForTasks()

        pspLog(.core, .notice, "Application did update eligible features")
        pendingTask = Task {
            await onEligibleFeaturesBlock?(features)
        }
        await pendingTask?.value
        pendingTask = nil
    }

    func onSaveProfile(_ profile: Profile, previous: Profile?) async throws {
        try await waitForTasks()

        pspLog(.core, .notice, "Application did save profile (\(profile.id))")
        guard let previous else {
            pspLog(.core, .debug, "\tProfile \(profile.id) is new, do nothing")
            return
        }
        let diff = profile.differences(from: previous)
        guard diff.isRelevantForReconnecting(to: profile) else {
            pspLog(.core, .debug, "\tProfile \(profile.id) changes are not relevant, do nothing")
            return
        }
        guard tunnelManager.isActiveProfile(withId: profile.id) else {
            pspLog(.core, .debug, "\tProfile \(profile.id) is not current, do nothing")
            return
        }
        let status = tunnelManager.status(ofProfileId: profile.id)
        guard [.active, .activating].contains(status) else {
            pspLog(.core, .debug, "\tConnection is not active (\(status)), do nothing")
            return
        }

        pendingTask = Task {
            do {
                pspLog(.core, .info, "\tReconnect profile \(profile.id)")
                try await tunnelManager.disconnect(from: profile.id)
                do {
                    try await tunnelManager.connect(with: profile)
                } catch ABI.AppError.interactiveLogin {
                    pspLog(.core, .info, "\tProfile \(profile.id) is interactive, do not reconnect")
                } catch {
                    pspLog(.core, .error, "\tUnable to reconnect profile \(profile.id): \(error)")
                }
            } catch {
                pspLog(.core, .error, "\tUnable to reinstate connection on save profile \(profile.id): \(error)")
            }
        }
        await pendingTask?.value
        pendingTask = nil
    }

    @discardableResult
    func waitForTasks() async throws -> Bool {
        var didLaunch = false

        // Require launch task to complete before performing anything else
        if launchTask == nil {
            launchTask = Task {
                do {
                    try await onLaunch()
                } catch {
                    launchTask = nil // Redo the launch task
                    throw ABI.AppError.couldNotLaunch(reason: error)
                }
            }
            didLaunch = true
        }

        // Will throw on .couldNotLaunch, and the next await
        // will re-attempt launch because launchTask == nil
        try await launchTask?.value

        // Wait for pending task if any
        await pendingTask?.value
        pendingTask = nil

        return didLaunch
    }

    func reloadExtensions() async {
        guard let extensionInstaller else { return }
        pspLog(.core, .info, "Extensions: load current status...")
        do {
            let result = try await extensionInstaller.load()
            pspLog(.core, .info, "Extensions: load result is \(result)")
        } catch {
            pspLog(.core, .error, "Extensions: load error: \(error)")
        }
    }

    var shouldInvalidateReceipt: Bool {
        // Always invalidate if "old" verification strategy
        guard kvStore.bool(forAppPreference: .relaxedVerification) else {
            return true
        }
        // Receipt never loaded, force load
        guard let didLoadReceiptDate else {
            return true
        }
        // Always force a reload if purchased products are
        // empty, because StoreKit may fail silently at times
        if iapManager.purchasedProducts.isEmpty {
            return true
        }
        // Must have elapsed more than invalidation period
        let elapsed = -didLoadReceiptDate.timeIntervalSinceNow
        return elapsed >= appConfiguration.constants.iap.receiptInvalidationInterval
    }
}

private extension Collection where Element == Profile.DiffResult {
    func isRelevantForReconnecting(to profile: Profile) -> Bool {
        contains {
            switch $0 {
            case .changedName:
                // Do not reconnect on profile rename
                return false
            case .changedBehavior(let changes):
                // Reconnect on changes to "Enforce tunnel"
                return changes.contains(.includesAllNetworks)
            case .changedModules(let ids):
                // Do not reconnect if only an on-demand module was changed
                if ids.count == 1, let onlyID = ids.first,
                   profile.module(withId: onlyID) is OnDemandModule {
                    return false
                }
                return true
            default:
                return true
            }
        }
    }
}
