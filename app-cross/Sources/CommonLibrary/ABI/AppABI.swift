// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@BusinessActor
public final class AppABI: Sendable {
    // Public ABI by domain
    public nonisolated let encoder: AppABIEncoderProtocol
    public nonisolated let iap: AppABIIAPProtocol
    public nonisolated let profile: AppABIProfileProtocol
    public nonisolated let registry: AppABIRegistryProtocol
    public nonisolated let tunnel: AppABITunnelProtocol
    public nonisolated let version: AppABIVersionProtocol
    public nonisolated let webReceiver: AppABIWebReceiverProtocol
#if !PSP_CROSS
    // Legacy managers not migrated to ABI, exposed as is
    @available(*, deprecated, message: "#1679")
    public nonisolated let apiManager: APIManager
    @available(*, deprecated, message: "#1679")
    public nonisolated let preferencesManager: PreferencesManager
#endif

    // Constants and storage
    private let appConfiguration: ABI.AppConfiguration
    private let kvStore: KeyValueStore
    // Managers wrapped in ABI
    private let configManager: ConfigManager
    private let extensionInstaller: ExtensionInstaller?
    private let iapManager: IAPManager
    private let logFormatter: LogFormatter
    private let profileManager: ProfileManager
    private let tunnelManager: TunnelManager
    private let versionChecker: VersionChecker
    private let webReceiverManager: WebReceiverManager
    // Purchases handler
    private let onEligibleFeaturesBlock: (@Sendable (Set<ABI.AppFeature>) async -> Void)?

    // Internal state
    private var launchTask: Task<Void, Error>?
    private var pendingTask: Task<Void, Never>?
    private var didLoadReceiptDate: Date?
    private var handler: ABI.EventHandler?
    private var subscriptions: [Task<Void, Never>]

    public init(
        apiManager: APIManager?,
        appConfiguration: ABI.AppConfiguration,
        appEncoder: AppEncoder,
        configManager: ConfigManager,
        extensionInstaller: ExtensionInstaller?,
        iapManager: IAPManager,
        kvStore: KeyValueStore,
        logFormatter: LogFormatter,
        preferencesManager: PreferencesManager?,
        profileManager: ProfileManager,
        registry partoutRegistry: CodingRegistry,
        tunnelManager: TunnelManager,
        versionChecker: VersionChecker,
        webReceiverManager: WebReceiverManager,
        onEligibleFeaturesBlock: (@Sendable (Set<ABI.AppFeature>) async -> Void)? = nil
    ) {
        self.appConfiguration = appConfiguration
        self.configManager = configManager
        self.extensionInstaller = extensionInstaller
        self.iapManager = iapManager
        self.kvStore = kvStore
        self.logFormatter = logFormatter
        self.profileManager = profileManager
        self.tunnelManager = tunnelManager
        self.versionChecker = versionChecker
        self.webReceiverManager = webReceiverManager
        self.onEligibleFeaturesBlock = onEligibleFeaturesBlock
#if !PSP_CROSS
        self.apiManager = apiManager ?? APIManager()
        self.preferencesManager = preferencesManager ?? PreferencesManager()
#endif
        subscriptions = []

        let supportsIAP = appConfiguration.bundle.distributionTarget.supportsIAP
        iapManager.isEnabled = supportsIAP && !kvStore.bool(forAppPreference: .skipsPurchases)

        encoder = AppABIEncoder(appEncoder: appEncoder)
        iap = AppABIIAP(
            iapManager: iapManager,
            kvStore: kvStore,
            supportsIAP: supportsIAP
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
}

extension AppABI {
    public func registerEvents(_ newHandler: ABI.EventHandler?) {
        let configEvents = configManager.didChange.subscribe()
        let iapEvents = iapManager.didChange.subscribe()
        let profileEvents = profileManager.didChange.subscribe()
        let tunnelEvents = tunnelManager.observeObjects()
        let versionEvents = versionChecker.didChange.subscribe()
        let webReceiverEvents = webReceiverManager.didChange.subscribe()

        // Set new handler
        handler = newHandler

        // Post initial state AFTER events registration (in case it was missed)
        iapManager.postInitialState()
        profileManager.postInitialState()

        subscriptions.append(Task { [weak self] in
            for await event in configEvents {
                guard let self else { return }
                dispatch(.config(event), handler)
            }
        })
        subscriptions.append(Task { [weak self] in
            for await event in iapEvents {
                guard let self else { return }
                dispatch(.iap(event), handler)
            }
        })
        subscriptions.append(Task { [weak self] in
            for await event in profileEvents {
                guard let self else { return }
                dispatch(.profile(event), handler)
            }
        })
        subscriptions.append(Task { [weak self] in
            for await event in tunnelEvents {
                guard let self else { return }
                dispatch(.tunnel(event), handler)
            }
        })
        subscriptions.append(Task { [weak self] in
            for await event in versionEvents {
                guard let self else { return }
                dispatch(.version(event), handler)
            }
        })
        subscriptions.append(Task { [weak self] in
            for await event in webReceiverEvents {
                guard let self else { return }
                switch event {
                case .newUpload(let payload):
                    do {
                        try await onWebUpload(payload.file)
                        dispatch(.webReceiver(event), handler)
                    } catch {
                        let failureEvent: ABI.WebReceiverEvent = .uploadFailure(.init(
                            error: error.localizedDescription
                        ))
                        dispatch(.webReceiver(failureEvent), handler)
                    }
                default:
                    dispatch(.webReceiver(event), handler)
                }
            }
        })
    }

    public func unregisterEvents() {
        handler = nil
    }

    func dispatch(_ event: ABI.Event, _ handler: ABI.EventHandler?) {
        guard let handler else { return }
        handler.callback(handler.context, event)
    }
}

// MARK: - Actions

private struct AppABIEncoder: AppABIEncoderProtocol {
    let appEncoder: AppEncoder

    func defaultFilename(for profileName: String) -> String {
        appEncoder.defaultFilename(for: profileName)
    }

    func json(fromProfile profile: Profile) throws -> String {
        try appEncoder.string(fromProfile: profile)
    }

    func writeToFile(_ profile: Profile) throws -> String {
        try appEncoder.writeToFile(profile)
    }
}

private struct AppABIIAP: AppABIIAPProtocol {
    let iapManager: IAPManager
    let kvStore: KeyValueStore
    let supportsIAP: Bool

    func enable(_ isEnabled: Bool) {
        iapManager.isEnabled = supportsIAP && isEnabled
        kvStore.set(!iapManager.isEnabled, forAppPreference: .skipsPurchases)
    }

    func verify(_ profile: Profile, extra: Set<ABI.AppFeature>?) throws {
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

    func suggestedProducts(for features: Set<ABI.AppFeature>, hints: Set<ABI.StoreProductHint>?) -> Set<ABI.AppProduct> {
        iapManager.suggestedProducts(for: features, hints: hints)
    }

    func purchasableProducts(for products: [ABI.AppProduct]) async throws -> [ABI.StoreProduct] {
        try await iapManager.fetchPurchasableProducts(for: products)
    }

    var verificationDelayMinutes: Int {
        iapManager.verificationDelayMinutes
    }
}

private struct AppABIProfile: AppABIProfileProtocol {
    let profileManager: ProfileManager
    let registry: CodingRegistry

    var isRemoteImportingEnabled: Bool {
        profileManager.isRemoteImportingEnabled
    }

    func save(_ profile: Profile, remotelyShared: Bool?) async throws {
        try await profileManager.save(profile, isLocal: true, remotelyShared: remotelyShared)
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

    func duplicate(_ id: Profile.ID) async throws {
        try await profileManager.duplicate(profileWithId: id)
    }

    func remove(_ id: Profile.ID) async {
        await profileManager.remove(withId: id)
    }

    func remove(_ ids: [Profile.ID]) async {
        await profileManager.remove(withIds: ids)
    }

    func removeAllRemote() async throws {
        try await profileManager.eraseRemotelySharedProfiles()
    }

    func profile(withId id: Profile.ID) -> Profile? {
        profileManager.profile(withId: id)
    }
}

private struct AppABIRegistry: AppABIRegistryProtocol {
    let registry: CodingRegistry

    func importedProfile(from input: ABI.ProfileImporterInput, passphrase: String?) throws -> Profile {
        try registry.importedProfile(from: input, passphrase: passphrase)
    }

    func newModule(ofType moduleType: ModuleType) -> any ModuleBuilder {
        registry.newModule(ofType: moduleType)
    }

    func validate(_ builder: any ModuleBuilder) throws {
        guard let impl = registry.implementation(for: builder.moduleType),
              let validator = impl as? ModuleBuilderValidator else {
            return
        }
        try validator.validate(builder)
    }

    func implementation(for moduleType: ModuleType) -> (any ModuleImplementation)? {
        registry.implementation(for: moduleType)
    }

    func resolvedModule(_ module: ProviderModule, in profile: Profile?) throws -> Module {
        try registry.resolvedModule(module, in: profile)
    }
}

private struct AppABITunnel: AppABITunnelProtocol {
    let tunnelManager: TunnelManager
    let logParameters: ABI.AppConstants.Log

    func connect(to profile: Profile, force: Bool) async throws {
        try await tunnelManager.connect(with: profile, force: force)
    }

//    func reconnect(to profileId: ABI.Identifier) async throws {
//        try await tunnel.
//    }

    func disconnect(from profileId: Profile.ID) async throws {
        try await tunnelManager.disconnect(from: profileId)
    }

    func currentLog() async -> [ABI.LogLine] {
        await tunnelManager.currentLog(parameters: logParameters)
    }

    func environmentValue(for key: AppABITunnelValueKey, ofProfileId profileId: Profile.ID) async -> Any? {
        switch key {
        case .openVPNServerConfiguration:
            await tunnelManager.value(
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
}

private struct AppABIWebReceiver: AppABIWebReceiverProtocol {
    let webReceiverManager: WebReceiverManager

    func start() throws {
        try webReceiverManager.start()
    }

    func stop() {
        webReceiverManager.stop()
    }
}

// MARK: - Logging

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

            // Imply some hidden preferences from config flags
            kvStore.preferences.newProfileEncoding = configManager.isActive(.newProfileEncoding)

            // Constrain .relaxedVerification preference to .allows and
            // .forces combinations in ConfigManager. At most, it's left as is
            kvStore.constrainRelaxedVerification(to: configManager)
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
            for await event in iapEvents {
                guard let self else { return }
                switch event {
                case .status(let payload):
                    // XXX: This was on .dropFirst() + .removeDuplicates()
                    pspLog(.iap, .info, "IAPManager.isEnabled -> \(payload.isEnabled)")
                    kvStore.set(!payload.isEnabled, forAppPreference: .skipsPurchases)
                    await iapManager.reloadReceipt()
                    didLoadReceiptDate = Date()
                case .eligibleFeatures(let payload):
                    // XXX: This was on .dropFirst() + .removeDuplicates()
                    do {
                        pspLog(.iap, .info, "IAPManager.eligibleFeatures -> \(payload.features)")
                        try await onEligibleFeatures(Set(payload.features))
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
            for await event in profileEvents {
                guard let self else { return }
                switch event {
                case .save(let payload):
                    do {
                        try await onSaveProfile(
                            payload.profile,
                            previous: payload.previous
                        )
                    } catch {
                        pspLog(.profiles, .error, "Unable to react to saved profile: \(error)")
                    }
                default:
                    break
                }
            }
        })
#if !PSP_CROSS
        do {
            pspLog(.core, .info, "\tFetch providers index...")
            try await apiManager.fetchIndex()
        } catch {
            pspLog(.core, .error, "\tUnable to fetch providers index: \(error)")
        }
#endif
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
        let status = tunnelManager.tunnelStatus(ofProfileId: profile.id)
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

    func onWebUpload(_ upload: ABI.WebFileUpload) async throws {
        pspLog(.web, .info, "Uploaded: \(upload.name), \(upload.contents.count) bytes")
        do {
            // Import
            var profile = try registry.importedProfile(
                from: .contents(filename: upload.name, data: upload.contents),
                passphrase: nil
            )
            // Add TV availability flag
            var builder = profile.builder()
            builder.attributes.isAvailableForTV = true
            profile = try builder.build()
            // Commit locally
            try await profileManager.save(profile, isLocal: true, remotelyShared: nil)
            // Refresh web receiver
            webReceiverManager.renewPasscode()
        } catch {
            pspLog(.web, .error, "Unable to import uploaded profile: \(error)")
            throw error
        }
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
