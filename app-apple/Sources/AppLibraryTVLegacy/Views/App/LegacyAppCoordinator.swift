// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

@available(*, deprecated, message: "#1594")
public struct LegacyAppCoordinator: View, LegacyAppCoordinatorConforming {

    @EnvironmentObject
    public var iapManager: IAPManager

    @Environment(\.appConfiguration)
    private var appConfiguration

    @Environment(\.logFormatterBlock)
    private var logFormatterBlock

    private let profileManager: ProfileManager

    public let tunnel: TunnelManager

    private let registry: Registry

    private let webReceiverManager: WebReceiverManager

    @State
    private var paywallReason: PaywallReason?

    @State
    private var paywallContinuation: (() -> Void)?

    @State
    private var interactiveObservable = InteractiveObservable()

    @State
    private var errorHandler: ErrorHandler = .default()

    public init(
        profileManager: ProfileManager,
        tunnel: TunnelManager,
        registry: Registry,
        webReceiverManager: WebReceiverManager
    ) {
        self.profileManager = profileManager
        self.tunnel = tunnel
        self.registry = registry
        self.webReceiverManager = webReceiverManager
        pp_log_g(.core, .info, "LegacyAppCordinator (ObservableObject)")
    }

    public var body: some View {
        debugChanges()
        return NavigationStack {
            TabView {
                connectionView.tabItem {
                    Text(Strings.Global.Nouns.connection)
                }
                profilesView.tabItem {
                    Text(Strings.Global.Nouns.profiles)
                }
//                searchView.tabItem {
//                    ThemeImage(.search)
//                }
                settingsView.tabItem {
                    ThemeImage(.settings)
                }
            }
            .navigationDestination(for: AppCoordinatorRoute.self, destination: pushDestination)
            .modifier(DynamicPaywallModifier(
                paywallReason: $paywallReason,
                paywallContinuation: paywallContinuation
            ))
            .withErrorHandler(errorHandler)
        }
    }
}

private extension LegacyAppCoordinator {
    var connectionView: some View {
        ConnectionView(
            profileManager: profileManager,
            tunnel: tunnel,
            interactiveObservable: interactiveObservable,
            errorHandler: errorHandler,
            flow: .init(
                onConnect: {
                    await onConnect($0, force: false)
                },
                onProviderEntityRequired: {
                    onProviderEntityRequired($0, force: false)
                }
            )
        )
    }

    var profilesView: some View {
        ProfilesView(
            profileManager: profileManager,
            webReceiverManager: webReceiverManager,
            registry: registry
        )
    }

//    var searchView: some View {
//        VStack {
//            Text("Search")
//        }
//    }

    var settingsView: some View {
        SettingsView(
            profileManager: profileManager,
            tunnel: tunnel
        )
    }
}

private extension LegacyAppCoordinator {

    @ViewBuilder
    func pushDestination(for item: AppCoordinatorRoute?) -> some View {
        switch item {
        case .appLog:
            DebugLogView(withAppParameters: appConfiguration.constants.log) {
                DebugLogContentView(lines: $0)
            }

        case .tunnelLog:
            DebugLogView(
                withTunnel: tunnel,
                parameters: appConfiguration.constants.log,
                logFormatterBlock: logFormatterBlock,
                content: {
                    DebugLogContentView(lines: $0)
                }
            )

        default:
            EmptyView()
        }
    }
}

// MARK: - Handlers

extension LegacyAppCoordinator {
    public func onInteractiveLogin(_ profile: Profile, _ onComplete: @escaping InteractiveObservable.CompletionBlock) {
        pspLog(.core, .info, "Present interactive login")
        interactiveObservable.present(
            with: ABI.AppProfile(native: profile),
            onComplete: onComplete
        )
    }

    public func onProviderEntityRequired(_ profile: Profile, force: Bool) {
        errorHandler.handle(
            title: profile.name,
            message: Strings.Alerts.Providers.MissingServer.message
        )
    }

    public func onPurchaseRequired(
        for profile: Profile,
        features: Set<ABI.AppFeature>,
        continuation: (() -> Void)?
    ) {
        pspLog(.core, .info, "Purchase required for features: \(features)")
        guard !iapManager.isLoadingReceipt else {
            let V = Strings.Views.Paywall.Alerts.Verification.self
            pspLog(.core, .info, "Present verification alert")
            errorHandler.handle(
                title: Strings.Views.Paywall.Alerts.Confirmation.title,
                message: [
                    V.Connect._1,
                    V.boot,
                    "\n\n",
                    V.Connect._2(iapManager.verificationDelayMinutes)
                ].joined(separator: " "),
                onDismiss: continuation
            )
            return
        }
        pspLog(.core, .info, "Present paywall")
        paywallContinuation = continuation

        setLater(.init(profile, requiredFeatures: features, action: .connect)) {
            paywallReason = $0
        }
    }

    public func onError(_ error: Error, title: String) {
        errorHandler.handle(
            error,
            title: title,
            message: Strings.Errors.App.tunnel
        )
    }
}

// MARK: - Paywall

private struct DynamicPaywallModifier: ViewModifier {

    @Environment(ConfigObservable.self)
    private var configObservable

    @Binding
    var paywallReason: PaywallReason?

    let paywallContinuation: (() -> Void)?

    func body(content: Content) -> some View {
        content.modifier(newModifier)
    }

    var newModifier: some ViewModifier {
        PaywallModifier(
            reason: $paywallReason,
            onAction: { _, _ in
                paywallContinuation?()
            }
        )
    }
}

// MARK: - Previews

#Preview {
    LegacyAppCoordinator(
        profileManager: .forPreviews,
        tunnel: .forPreviews,
        registry: Registry(),
        webReceiverManager: WebReceiverManager()
    )
    .withMockEnvironment()
}
