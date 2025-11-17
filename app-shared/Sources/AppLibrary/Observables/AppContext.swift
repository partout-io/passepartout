// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Combine
import CommonLibrary
import Foundation
import Partout

// FIXME: #1594, Split into AppContext (AppLibrary) and CommonContext (CommonLibrary)
@MainActor
public final class AppContext {

    // MARK: Environment/Observables

    public let appConfiguration: ABI.AppConfiguration

    public let appearanceObservable: AppearanceObservable

    public let appEncoderObservable: AppEncoderObservable

    public let appFormatter: AppFormatter

    public let iapObservable: IAPObservable

    public let onboardingObservable: OnboardingObservable

    public let profileObservable: ProfileObservable

    public let tunnelObservable: TunnelObservable

    public let viewLogger: ViewLogger

    // MARK: Internal

    private let sysexManager: SystemExtensionManager?

    // FIXME: #1594, Drop or make internal

    public let apiManager: APIManager

    public let configManager: ConfigManager

    public let iapManager: IAPManager

    public let kvManager: KeyValueManager

    public let preferencesManager: PreferencesManager

    public let profileManager: ProfileManager

    public let registry: Registry

    public let tunnel: ExtendedTunnel

    public let versionChecker: VersionChecker

    public let webReceiverManager: WebReceiverManager

    // MARK: Other

    private let receiptInvalidationInterval: TimeInterval

    private let onEligibleFeaturesBlock: ((Set<ABI.AppFeature>) async -> Void)?

    // MARK: Internal state

    private var launchTask: Task<Void, Error>?

    private var pendingTask: Task<Void, Never>?

    private var didLoadReceiptDate: Date?

    private var subscriptions: Set<AnyCancellable>

    // MARK: - Init

    public init(
        apiManager: APIManager,
        appConfiguration: ABI.AppConfiguration,
        appEncoder: AppEncoder,
        configManager: ConfigManager,
        iapManager: IAPManager,
        kvManager: KeyValueManager,
        logger: AppLogger,
        onboardingObservable: OnboardingObservable? = nil,
        preferencesManager: PreferencesManager,
        profileManager: ProfileManager,
        registry: Registry,
        sysexManager: SystemExtensionManager?,
        tunnel: ExtendedTunnel,
        versionChecker: VersionChecker,
        webReceiverManager: WebReceiverManager,
        onEligibleFeaturesBlock: ((Set<ABI.AppFeature>) async -> Void)? = nil
    ) {
        // Internal
        self.apiManager = apiManager
        self.configManager = configManager
        self.iapManager = iapManager
        self.kvManager = kvManager
        self.preferencesManager = preferencesManager
        self.profileManager = profileManager
        self.registry = registry
        self.sysexManager = sysexManager
        self.tunnel = tunnel
        self.versionChecker = versionChecker
        self.webReceiverManager = webReceiverManager

        // Environment
        self.appConfiguration = appConfiguration
        appFormatter = AppFormatter(constants: appConfiguration.constants)
        appearanceObservable = AppearanceObservable(kvManager: kvManager)
        appEncoderObservable = AppEncoderObservable(encoder: appEncoder)
        iapObservable = IAPObservable(logger: logger, iapManager: iapManager)
        self.onboardingObservable = onboardingObservable ?? OnboardingObservable()
        profileObservable = ProfileObservable(logger: logger, profileManager: profileManager)
        tunnelObservable = TunnelObservable(logger: logger, extendedTunnel: tunnel)
        viewLogger = ViewLogger(strategy: logger)

        // Other
        receiptInvalidationInterval = appConfiguration.constants.iap.receiptInvalidationInterval
        self.onEligibleFeaturesBlock = onEligibleFeaturesBlock

        didLoadReceiptDate = nil
        subscriptions = []
    }
}

// MARK: - Observation

// invoked by AppDelegate
extension AppContext {
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

// invoked on internal events
private extension AppContext {
    func onLaunch() async throws {
        pp_log_g(.App.core, .notice, "Application did launch")

        pp_log_g(.App.profiles, .info, "\tRead and observe local profiles...")
        try await profileManager.observeLocal()

        pp_log_g(.App.profiles, .info, "\tObserve in-app events...")
        iapManager.observeObjects(withProducts: true)

        // Defer loads to not block app launch
        Task {
            await iapManager.reloadReceipt()
            didLoadReceiptDate = Date()
        }
        Task {
            await reloadSystemExtension()
        }

        iapManager
            .$isEnabled
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] in
                pp_log_g(.App.iap, .info, "IAPManager.isEnabled -> \($0)")
                self?.kvManager.set(!$0, forAppPreference: .skipsPurchases)
                Task {
                    await self?.iapManager.reloadReceipt()
                    self?.didLoadReceiptDate = Date()
                }
            }
            .store(in: &subscriptions)

        pp_log_g(.App.profiles, .info, "\tObserve eligible features...")
        iapManager
            .$eligibleFeatures
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] eligible in
                Task {
                    try await self?.onEligibleFeatures(eligible)
                }
            }
            .store(in: &subscriptions)

        pp_log_g(.App.profiles, .info, "\tObserve changes in ProfileManager...")
        profileManager
            .didChange
            .sink { [weak self] event in
                switch event {
                case .save(let profile, let previousProfile):
                    Task {
                        try await self?.onSaveProfile(profile, previous: previousProfile)
                    }

                default:
                    break
                }
            }
            .store(in: &subscriptions)

        do {
            pp_log_g(.App.core, .info, "\tFetch providers index...")
            try await apiManager.fetchIndex()
        } catch {
            pp_log_g(.App.core, .error, "\tUnable to fetch providers index: \(error)")
        }
    }

    func onForeground() async throws {

        // onForeground() is redundant after launch
        let didLaunch = try await waitForTasks()
        guard !didLaunch else {
            return
        }

        pp_log_g(.App.core, .notice, "Application did enter foreground")
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

        pp_log_g(.App.core, .notice, "Application did update eligible features")
        pendingTask = Task {
            await onEligibleFeaturesBlock?(features)
        }
        await pendingTask?.value
        pendingTask = nil
    }

    func onSaveProfile(_ profile: Profile, previous: Profile?) async throws {
        try await waitForTasks()

        pp_log_g(.App.core, .notice, "Application did save profile (\(profile.id))")
        guard let previous else {
            pp_log_g(.App.core, .debug, "\tProfile \(profile.id) is new, do nothing")
            return
        }
        let diff = profile.differences(from: previous)
        guard diff.isRelevantForReconnecting(to: profile) else {
            pp_log_g(.App.core, .debug, "\tProfile \(profile.id) changes are not relevant, do nothing")
            return
        }
        guard tunnel.isActiveProfile(withId: profile.id) else {
            pp_log_g(.App.core, .debug, "\tProfile \(profile.id) is not current, do nothing")
            return
        }
        let status = tunnel.status(ofProfileId: profile.id)
        guard [.active, .activating].contains(status) else {
            pp_log_g(.App.core, .debug, "\tConnection is not active (\(status)), do nothing")
            return
        }

        pendingTask = Task {
            do {
                pp_log_g(.App.core, .info, "\tReconnect profile \(profile.id)")
                try await tunnel.disconnect(from: profile.id)
                do {
                    try await tunnel.connect(with: profile)
                } catch ABI.AppError.interactiveLogin {
                    pp_log_g(.App.core, .info, "\tProfile \(profile.id) is interactive, do not reconnect")
                } catch {
                    pp_log_g(.App.core, .error, "\tUnable to reconnect profile \(profile.id): \(error)")
                }
            } catch {
                pp_log_g(.App.core, .error, "\tUnable to reinstate connection on save profile \(profile.id): \(error)")
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
        guard let sysexManager else {
            return
        }
        pp_log_g(.App.core, .info, "System Extension: load current status...")
        do {
            let result = try await sysexManager.load()
            pp_log_g(.App.core, .info, "System Extension: load result is \(result)")
        } catch {
            pp_log_g(.App.core, .error, "System Extension: load error: \(error)")
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
        return elapsed >= receiptInvalidationInterval
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
