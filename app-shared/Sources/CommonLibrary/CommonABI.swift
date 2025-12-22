// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class CommonABI: ABIProtocol, Sendable {
    // MARK: Business

    // FIXME: #1594, Make these private after observables
    public let appConfiguration: ABI.AppConfiguration
    public let appEncoder: AppEncoder
    public let configManager: ConfigManager
    public let iapManager: IAPManager
    public let kvManager: KeyValueManager
    public let logger: AppLogger
    public let profileManager: ProfileManager
    public let registry: Registry
    public let sysexManager: ExtensionInstaller?
    public let tunnel: ExtendedTunnel
    public let versionChecker: VersionChecker
    public let webReceiverManager: WebReceiverManager
    private let onEligibleFeaturesBlock: ((Set<ABI.AppFeature>) async -> Void)?
    // Legacy
    public let apiManager: APIManager
    public let preferencesManager: PreferencesManager

    // MARK: Internal state

    private var launchTask: Task<Void, Error>?
    private var pendingTask: Task<Void, Never>?
    private var didLoadReceiptDate: Date?
    private var subscriptions: [Task<Void, Never>]

    public init(
        apiManager: APIManager,
        appConfiguration: ABI.AppConfiguration,
        appEncoder: AppEncoder,
        configManager: ConfigManager,
        iapManager: IAPManager,
        kvManager: KeyValueManager,
        logger: AppLogger,
        preferencesManager: PreferencesManager,
        profileManager: ProfileManager,
        registry: Registry,
        sysexManager: ExtensionInstaller?,
        tunnel: ExtendedTunnel,
        versionChecker: VersionChecker,
        webReceiverManager: WebReceiverManager,
        onEligibleFeaturesBlock: ((Set<ABI.AppFeature>) async -> Void)? = nil
    ) {
        self.apiManager = apiManager
        self.appConfiguration = appConfiguration
        self.appEncoder = appEncoder
        self.configManager = configManager
        self.iapManager = iapManager
        self.kvManager = kvManager
        self.logger = logger
        self.preferencesManager = preferencesManager
        self.profileManager = profileManager
        self.registry = registry
        self.sysexManager = sysexManager
        self.tunnel = tunnel
        self.versionChecker = versionChecker
        self.webReceiverManager = webReceiverManager
        self.onEligibleFeaturesBlock = onEligibleFeaturesBlock
        subscriptions = []
    }

    public func registerEvents(context: ABIEventContext?, callback: @escaping EventCallback) {
        let profileEvents = profileManager.didChange.subscribe()
        let tunnelEvents = tunnel.didChange.subscribe()
        let iapEvents = iapManager.didChange.subscribe()
        let webReceiverUploads = webReceiverManager.files
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
            for await event in iapEvents {
                callback(context, .iap(event))
            }
        })
        subscriptions.append(Task {
            for await upload in webReceiverUploads {
                callback(context, .webReceiver(.newUpload(upload)))
            }
        })
    }
}

// MARK: - Actions

extension CommonABI {
    // MARK: Config

    public func configRefreshBundle() async {
        await configManager.refreshBundle()
    }

    public func configIsActive(_ flag: ABI.ConfigFlag) -> Bool {
        configManager.isActive(flag)
    }

    public func configData(for flag: ABI.ConfigFlag) -> JSON? {
        configManager.data(for: flag)
    }

    public var configActiveFlags: Set<ABI.ConfigFlag> {
        configManager.activeFlags
    }

    // MARK: Encoder

    public func encoderDefaultFilename(for profile: ABI.AppProfile) -> String {
        appEncoder.defaultFilename(for: profile.native)
    }

    public func encoderProfile(fromString string: String) throws -> ABI.AppProfile {
        try ABI.AppProfile(native: appEncoder.profile(fromString: string))
    }

    public func encoderJSON(fromProfile profile: ABI.AppProfile) throws -> String {
        try appEncoder.json(fromProfile: profile.native)
    }

    public func encoderWriteToFile(_ profile: ABI.AppProfile) throws -> String {
        try appEncoder.writeToFile(profile.native)
    }

    // MARK: IAP

    public func iapVerify(_ profile: ABI.AppProfile) throws {
        try iapManager.verify(profile.native)
    }

    public var iapIsBeta: Bool {
        iapManager.isBeta
    }

    public var iapVerificationDelayMinutes: Int {
        iapManager.verificationDelayMinutes
    }

    // MARK: Profile

    public func profile(withId id: ABI.AppIdentifier) -> ABI.AppProfile? {
        profileManager.profile(withId: id)
    }

    public func profileNew(named name: String) async throws {
        var builder = Profile.Builder()
        builder.name = name
        let profile = try builder.build()
        try await profileManager.save(profile, isLocal: true)
    }

    public func profileSave(_ profile: ABI.AppProfile, sharing: ABI.ProfileSharingFlag?) async throws {
        try await profileManager.save(profile.native, isLocal: true, sharing: sharing)
    }

    public func profileImportText(_ text: String, filename: String, passphrase: String?) async throws {
        try await profileManager.import(.contents(filename: filename, data: text), passphrase: passphrase)
    }

    public func profileImportFile(_ path: String, passphrase: String?) async throws {
        try await profileManager.import(.file(URL(fileURLWithPath: path)), passphrase: passphrase)
    }

    public func profileDup(_ id: ABI.AppIdentifier) async throws {
        try await profileManager.duplicate(profileWithId: id)
    }

    public func profileRemove(_ id: ABI.AppIdentifier) async {
        await profileManager.remove(withId: id)
    }

    public func profileRemove(_ ids: [ABI.AppIdentifier]) async {
        await profileManager.remove(withIds: ids)
    }

    public func profileRemoveAllRemote() async throws {
        try await profileManager.eraseRemotelySharedProfiles()
    }

    // MARK: Tunnel

    public func tunnelConnect(to profile: ABI.AppProfile, force: Bool) async throws {
        try await tunnel.connect(with: profile.native, force: force)
    }

    //    public func tunnelReconnect(to profileId: ABI.Identifier) async throws {
    //        try await tunnel.
    //    }

    public func tunnelDisconnect(from profileId: ABI.AppIdentifier) async throws {
        try await tunnel.disconnect(from: profileId)
    }

    public func tunnelCurrentLog() async -> [ABI.AppLogLine] {
        await tunnel.currentLog(parameters: appConfiguration.constants.log)
    }

    public func tunnelLastError(ofProfileId profileId: ABI.AppIdentifier) -> ABI.AppError? {
        tunnel.lastError(ofProfileId: profileId)
    }

    public func tunnelTransfer(ofProfileId profileId: ABI.AppIdentifier) -> ABI.ProfileTransfer? {
        tunnel.transfer(ofProfileId: profileId)
    }

    // MARK: Version

    public func versionCheckLatestRelease() async {
        await versionChecker.checkLatestRelease()
    }

    public var versionLatestRelease: ABI.VersionRelease? {
        versionChecker.latestRelease
    }

    // MARK: Web receiver

    public func webReceiverStart() throws {
        try webReceiverManager.start()
    }

    public func webReceiverStop() {
        webReceiverManager.stop()
    }

    public func webReceiverRefresh() {
        webReceiverManager.renewPasscode()
    }

    public var webReceiverIsStarted: Bool {
        webReceiverManager.isStarted
    }

    public var webReceiverWebsite: ABI.WebsiteWithPasscode? {
        webReceiverManager.website
    }
}

// MARK: - Observation

// Invoked by AppDelegate
extension CommonABI {
    public func onApplicationActive() {
        Task {
            // XXX: Should handle ABI.AppError.couldNotLaunch (although extremely rare)
            try await onForeground()

            await configManager.refreshBundle()
            await versionChecker.checkLatestRelease()

            // Propagate active config flags to tunnel via preferences
            kvManager.preferences.configFlags = configManager.activeFlags

            // Disable .relaxedVerification if ABI.ConfigFlag disallows it
            if !configManager.isActive(.allowsRelaxedVerification) {
                kvManager.set(false, forAppPreference: .relaxedVerification)
            }
        }
    }
}

// Invoked on internal events
private extension CommonABI {
    func onLaunch() async throws {
        logger.log(.core, .notice, "Application did launch")

        logger.log(.profiles, .info, "\tRead and observe local profiles...")
        try await profileManager.observeLocal()

        logger.log(.profiles, .info, "\tObserve in-app events...")
        iapManager.observeObjects(withProducts: true)

        // Defer loads to not block app launch
        Task {
            await iapManager.reloadReceipt()
            didLoadReceiptDate = Date()
        }
        Task {
            await reloadSystemExtension()
        }

        logger.log(.iap, .info, "\tObserve changes in IAPManager...")
        let iapEvents = iapManager.didChange.subscribe()
        subscriptions.append(Task { [weak self] in
            guard let self else { return }
            for await event in iapEvents {
                switch event {
                case .status(let isEnabled):
                    // FIXME: #1594, .dropFirst() + .removeDuplicates()
                    logger.log(.iap, .info, "IAPManager.isEnabled -> \(isEnabled)")
                    kvManager.set(!isEnabled, forAppPreference: .skipsPurchases)
                    await iapManager.reloadReceipt()
                    didLoadReceiptDate = Date()
                case .eligibleFeatures(let features):
                    // FIXME: #1594, .dropFirst() + .removeDuplicates()
                    do {
                        logger.log(.iap, .info, "IAPManager.eligibleFeatures -> \(features)")
                        try await onEligibleFeatures(features)
                    } catch {
                        logger.log(.iap, .error, "Unable to react to eligible features: \(error)")
                    }
                default:
                    break
                }
            }
        })

        logger.log(.profiles, .info, "\tObserve changes in ProfileManager...")
        let profileEvents = profileManager.didChange.subscribe()
        subscriptions.append(Task { [weak self] in
            guard let self else { return }
            for await event in profileEvents {
                switch event {
                case .save(let profile, let previousProfile):
                    do {
                        try await onSaveProfile(profile, previous: previousProfile)
                    } catch {
                        logger.log(.profiles, .error, "Unable to react to saved profile: \(error)")
                    }
                default:
                    break
                }
            }
        })

        do {
            logger.log(.core, .info, "\tFetch providers index...")
            try await apiManager.fetchIndex()
        } catch {
            logger.log(.core, .error, "\tUnable to fetch providers index: \(error)")
        }
    }

    func onForeground() async throws {

        // onForeground() is redundant after launch
        let didLaunch = try await waitForTasks()
        guard !didLaunch else {
            return
        }

        logger.log(.core, .notice, "Application did enter foreground")
        pendingTask = Task {
            await reloadSystemExtension()

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

        logger.log(.core, .notice, "Application did update eligible features")
        pendingTask = Task {
            await onEligibleFeaturesBlock?(features)
        }
        await pendingTask?.value
        pendingTask = nil
    }

    func onSaveProfile(_ profile: Profile, previous: Profile?) async throws {
        try await waitForTasks()

        logger.log(.core, .notice, "Application did save profile (\(profile.id))")
        guard let previous else {
            logger.log(.core, .debug, "\tProfile \(profile.id) is new, do nothing")
            return
        }
        let diff = profile.differences(from: previous)
        guard diff.isRelevantForReconnecting(to: profile) else {
            logger.log(.core, .debug, "\tProfile \(profile.id) changes are not relevant, do nothing")
            return
        }
        guard tunnel.isActiveProfile(withId: profile.id) else {
            logger.log(.core, .debug, "\tProfile \(profile.id) is not current, do nothing")
            return
        }
        let status = tunnel.status(ofProfileId: profile.id)
        guard [.active, .activating].contains(status) else {
            logger.log(.core, .debug, "\tConnection is not active (\(status)), do nothing")
            return
        }

        pendingTask = Task {
            do {
                logger.log(.core, .info, "\tReconnect profile \(profile.id)")
                try await tunnel.disconnect(from: profile.id)
                do {
                    try await tunnel.connect(with: profile)
                } catch ABI.AppError.interactiveLogin {
                    logger.log(.core, .info, "\tProfile \(profile.id) is interactive, do not reconnect")
                } catch {
                    logger.log(.core, .error, "\tUnable to reconnect profile \(profile.id): \(error)")
                }
            } catch {
                logger.log(.core, .error, "\tUnable to reinstate connection on save profile \(profile.id): \(error)")
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

    func reloadSystemExtension() async {
        guard let sysexManager else { return }
        logger.log(.core, .info, "System Extension: load current status...")
        do {
            let result = try await sysexManager.load()
            logger.log(.core, .info, "System Extension: load result is \(result)")
        } catch {
            logger.log(.core, .error, "System Extension: load error: \(error)")
        }
    }

    var shouldInvalidateReceipt: Bool {
        // Always invalidate if "old" verification strategy
        guard kvManager.bool(forAppPreference: .relaxedVerification) else {
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

extension Collection where Element == Profile.DiffResult {
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
