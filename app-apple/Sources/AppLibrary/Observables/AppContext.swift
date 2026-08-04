// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary

@MainActor
public final class AppContext {
    public let appConfiguration: ABI.AppConfiguration

    // Manager-backed observables
    public let appEncoderObservable: AppEncoderObservable
    public let configObservable: ConfigObservable
    public let iapObservable: IAPObservable
    public let profileObservable: ProfileObservable
    public let registryObservable: RegistryObservable
    public let versionObservable: VersionObservable
    public let webReceiverObservable: WebReceiverObservable

    // Legacy managers not migrated to observables
    @available(*, deprecated, message: "#1679")
    public let apiManager: APIManager
    @available(*, deprecated, message: "#1679")
    public let preferencesManager: PreferencesManager

    // Tunnel concerns
    public let tunnelObservable: TunnelObservable

    // View concerns
    public let appFormatter: AppFormatter
    public let onboardingObservable: OnboardingObservable
    public let userPreferences: UserPreferencesObservable

    // Managers
    private let configManager: ConfigManager
    private let extensionInstaller: ExtensionInstaller?
    private let iapManager: IAPManager
    private let preferences: AppPreferencesStore
    private let profileManager: ProfileManager
    private let registry: CodingRegistry
    private let versionChecker: VersionChecker
    private let webReceiverManager: WebReceiverManager

    // Purchases handler
    private let onEligibleFeaturesBlock: (@Sendable (Set<ABI.AppFeature>) async -> Void)?

    // Internal state
    private var launchTask: Task<Void, Error>?
    private var pendingTask: Task<Void, Never>?
    private var didLoadReceiptDate: Date?
    private var subscriptions: [Task<Void, Never>]

    public init(
        apiManager: APIManager,
        appConfiguration: ABI.AppConfiguration,
        appEncoder: AppEncoder,
        configManager: ConfigManager,
        defaults: UserDefaults,
        extensionInstaller: ExtensionInstaller?,
        iapManager: IAPManager,
        preferences: AppPreferencesStore,
        preferencesManager: PreferencesManager,
        profileManager: ProfileManager,
        registry: CodingRegistry,
        tunnelObservable: TunnelObservable,
        versionChecker: VersionChecker,
        webReceiverManager: WebReceiverManager,
        onEligibleFeaturesBlock: (@Sendable (Set<ABI.AppFeature>) async -> Void)? = nil
    ) {
        self.apiManager = apiManager
        self.appConfiguration = appConfiguration
        self.configManager = configManager
        self.extensionInstaller = extensionInstaller
        self.iapManager = iapManager
        self.preferences = preferences
        self.preferencesManager = preferencesManager
        self.profileManager = profileManager
        self.registry = registry
        self.tunnelObservable = tunnelObservable
        self.versionChecker = versionChecker
        self.webReceiverManager = webReceiverManager
        self.onEligibleFeaturesBlock = onEligibleFeaturesBlock
        subscriptions = []

        let supportsIAP = appConfiguration.bundle.distributionTarget.supportsIAP
        iapManager.isEnabled = supportsIAP && !preferences[\.skipsPurchases]

        // Manager-backed observables
        appEncoderObservable = AppEncoderObservable(appEncoder: appEncoder)
        configObservable = ConfigObservable()
        iapObservable = IAPObservable(
            iapManager: iapManager,
            supportsIAP: supportsIAP
        )
        profileObservable = ProfileObservable(
            profileManager: profileManager,
            registry: registry
        )
        registryObservable = RegistryObservable(registry: registry)
        versionObservable = VersionObservable(appConfiguration: appConfiguration)
        webReceiverObservable = WebReceiverObservable(
            webReceiverManager: webReceiverManager
        )

        // View concerns
        appFormatter = AppFormatter(constants: appConfiguration.constants)
        userPreferences = UserPreferencesObservable(preferences: preferences, ui: defaults)
        onboardingObservable = OnboardingObservable(userPreferences: userPreferences)

        observeManagerEvents()
        tunnelObservable.observeObjects()
    }

    deinit {
        pspLog(.core, .debug, "Deinit AppContext")
        subscriptions.forEach { $0.cancel() }
    }
}

// MARK: - Application lifecycle

extension AppContext {
    public func onApplicationActive() {
        Task {
            // XXX: Should handle ABI.AppError.couldNotLaunch (although extremely rare)
            try await onForeground()

            await configManager.refreshBundle()
            await versionChecker.checkLatestRelease()

            preferences.request(changesTo: [
                .configFlags
            ]) {
                // Propagate active config flags to tunnel via preferences
                $0.configFlags = Array(configManager.activeFlags)
            }
        }
    }
}

// MARK: - Manager events

private extension AppContext {
    func observeManagerEvents() {
        let configEvents = configManager.didChange.subscribe()
        let iapEvents = iapManager.didChange.subscribe()
        let profileEvents = profileManager.didChange.subscribe()
        let versionEvents = versionChecker.didChange.subscribe()
        let webReceiverEvents = webReceiverManager.didChange.subscribe()

        // Observables fully rely on event updates for their state, including
        // initial manager state. Post it only after creating subscriptions.
        iapManager.postInitialState()
        profileManager.postInitialState()

        subscriptions.append(Task { [weak self] in
            for await event in configEvents {
                guard let self else { return }
                dispatch(.config(event))
            }
        })
        subscriptions.append(Task { [weak self] in
            for await event in iapEvents {
                guard let self else { return }
                dispatch(.iap(event))
            }
        })
        subscriptions.append(Task { [weak self] in
            for await event in profileEvents {
                guard let self else { return }
                dispatch(.profile(event))
            }
        })
        subscriptions.append(Task { [weak self] in
            for await event in versionEvents {
                guard let self else { return }
                dispatch(.version(event))
            }
        })
        subscriptions.append(Task { [weak self] in
            for await event in webReceiverEvents {
                guard let self else { return }
                switch event {
                case .newUpload(let payload):
                    do {
                        try await onWebUpload(payload.file)
                        dispatch(.webReceiver(event))
                    } catch {
                        let failureEvent: ABI.WebReceiverEvent = .uploadFailure(.init(
                            error: error.localizedDescription
                        ))
                        dispatch(.webReceiver(failureEvent))
                    }
                default:
                    dispatch(.webReceiver(event))
                }
            }
        })
    }

    func dispatch(_ event: ABI.Event) {
        switch event {
        case .config(let event):
            configObservable.onUpdate(event)
        case .iap(let event):
            iapObservable.onUpdate(event)
        case .mixed:
            break
        case .profile(let event):
            profileObservable.onUpdate(event)
        case .version(let event):
            versionObservable.onUpdate(event)
        case .webReceiver(let event):
            webReceiverObservable.onUpdate(event)
        }

        // Report all events to these.
        tunnelObservable.onUpdate(event)
        userPreferences.onUpdate(event)
    }
}

// MARK: - Internal lifecycle

private extension AppContext {
    func onLaunch() async throws {
        pspLog(.core, .notice, "Application did launch")

        pspLog(.profiles, .info, "\tRead and observe local profiles...")
        try await profileManager.observeLocal()

        pspLog(.profiles, .info, "\tObserve in-app events...")
        iapManager.observeObjects(withProducts: true)

        // Defer loads to not block app launch.
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
                    // XXX: This was on .dropFirst() + .removeDuplicates().
                    pspLog(.iap, .info, "IAPManager.isEnabled -> \(payload.isEnabled)")
                    await iapManager.reloadReceipt()
                    didLoadReceiptDate = Date()
                case .eligibleFeatures(let payload):
                    // XXX: This was on .dropFirst() + .removeDuplicates().
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

        do {
            pspLog(.core, .info, "\tFetch providers index...")
            try await apiManager.fetchIndex()
        } catch {
            pspLog(.core, .error, "\tUnable to fetch providers index: \(error)")
        }
    }

    func onForeground() async throws {
        // onForeground() is redundant after launch.
        let didLaunch = try await waitForTasks()
        guard !didLaunch else {
            return
        }
        assert(pendingTask == nil)

        pspLog(.core, .notice, "Application did enter foreground")
        pendingTask = Task {
            await reloadExtensions()

            // Do not reload the receipt unconditionally.
            if shouldInvalidateReceipt {
                await iapManager.reloadReceipt()
                didLoadReceiptDate = Date()
            }

            // Re-fetch local profiles to sync with external changes
            do {
                try await profileManager.refreshLocalProfiles()
            } catch {
                pspLog(.core, .error, "Unable to refresh local profiles: \(error)")
            }
        }
        await pendingTask?.value
        pendingTask = nil
    }

    func onEligibleFeatures(_ features: Set<ABI.AppFeature>) async throws {
        try await waitForTasks()
        assert(pendingTask == nil)

        pspLog(.core, .notice, "Application did update eligible features")
        pendingTask = Task {
            await onEligibleFeaturesBlock?(features)
        }
        await pendingTask?.value
        pendingTask = nil
    }

    func onSaveProfile(_ profile: Profile, previous: Profile?) async throws {
        try await waitForTasks()
        assert(pendingTask == nil)

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

        // Suggest tunnel reconnection (may or may not happen).
        dispatch(.mixed(.shouldReconnect(.init(profile: profile))))
    }

    func onWebUpload(_ upload: ABI.WebFileUpload) async throws {
        pspLog(.web, .info, "Uploaded: \(upload.name), \(upload.contents.count) bytes")
        do {
            var profile = try registry.importedProfile(
                from: .contents(filename: upload.name, data: upload.contents),
                passphrase: nil
            )
            var builder = profile.builder()
            builder.attributes.isAvailableForTV = true
            profile = try builder.build()
            try await profileManager.save(
                profile,
                isLocal: true,
                remotelyShared: nil
            )
            webReceiverManager.renewPasscode()
        } catch {
            pspLog(.web, .error, "Unable to import uploaded profile: \(error)")
            throw error
        }
    }

    @discardableResult
    func waitForTasks() async throws -> Bool {
        var didLaunch = false

        // Require launch task to complete before performing anything else.
        if launchTask == nil {
            launchTask = Task {
                do {
                    try await onLaunch()
                } catch {
                    pspLog(.core, .fault, "Unable to launch: \(error)")
                    launchTask = nil // Redo the launch task.
                    throw ABI.AppError.couldNotLaunch(reason: error)
                }
            }
            didLaunch = true
        }

        // Will throw on .couldNotLaunch, and the next await will retry launch.
        try await launchTask?.value

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
        guard let didLoadReceiptDate else {
            return true
        }
        if iapManager.purchasedProducts.isEmpty {
            return true
        }
        let elapsed = -didLoadReceiptDate.timeIntervalSinceNow
        return elapsed >= appConfiguration.constants.iap.receiptInvalidationInterval
    }
}

private extension Collection where Element == Profile.DiffResult {
    func isRelevantForReconnecting(to profile: Profile) -> Bool {
        contains {
            switch $0 {
            case .changedName:
                return false
            case .changedBehavior(let changes):
                return changes.contains(.includesAllNetworks)
            case .changedModules(let ids):
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
