// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import SwiftUI

public struct AppCoordinator: View, AppCoordinatorConforming {

    @EnvironmentObject
    public var iapManager: IAPManager

    private let profileObservable: ProfileObservable

    public let tunnel: ExtendedTunnel

    private let webReceiverManager: WebReceiverManager

    @State
    private var paywallReason: PaywallReason?

    @State
    private var paywallContinuation: (() -> Void)?

    @StateObject
    private var interactiveManager = InteractiveManager()

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    public init(
        profileObservable: ProfileObservable,
        tunnel: ExtendedTunnel,
        webReceiverManager: WebReceiverManager
    ) {
        self.profileObservable = profileObservable
        self.tunnel = tunnel
        self.webReceiverManager = webReceiverManager
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

private extension AppCoordinator {
    var connectionView: some View {
        ConnectionView(
            profileObservable: profileObservable,
            tunnel: tunnel,
            interactiveManager: interactiveManager,
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
            profileObservable: profileObservable,
            webReceiverManager: webReceiverManager
        )
    }

//    var searchView: some View {
//        VStack {
//            Text("Search")
//        }
//    }

    var settingsView: some View {
        SettingsView(
            profileObservable: profileObservable,
            tunnel: tunnel
        )
    }
}

private extension AppCoordinator {

    @ViewBuilder
    func pushDestination(for item: AppCoordinatorRoute?) -> some View {
        switch item {
        case .appLog:
            DebugLogView(withAppParameters: Resources.constants.log) {
                DebugLogContentView(lines: $0)
            }

        case .tunnelLog:
            DebugLogView(withTunnel: tunnel, parameters: Resources.constants.log) {
                DebugLogContentView(lines: $0)
            }

        default:
            EmptyView()
        }
    }
}

// MARK: - Handlers

extension AppCoordinator {
    public func onInteractiveLogin(_ profile: Profile, _ onComplete: @escaping InteractiveManager.CompletionBlock) {
        pp_log_g(.App.core, .info, "Present interactive login")
        interactiveManager.present(
            with: profile,
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
        features: Set<AppFeature>,
        continuation: (() -> Void)?
    ) {
        pp_log_g(.App.core, .info, "Purchase required for features: \(features)")
        guard !iapManager.isLoadingReceipt else {
            let V = Strings.Views.Paywall.Alerts.Verification.self
            pp_log_g(.App.core, .info, "Present verification alert")
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
        pp_log_g(.App.core, .info, "Present paywall")
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

    @EnvironmentObject
    private var configManager: ConfigManager

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

// FIXME: #1594, Previews
//#Preview {
//    AppCoordinator(
//        profileObservable: .forPreviews,
//        tunnel: .forPreviews,
//        webReceiverManager: WebReceiverManager()
//    )
//    .withMockEnvironment()
//}
