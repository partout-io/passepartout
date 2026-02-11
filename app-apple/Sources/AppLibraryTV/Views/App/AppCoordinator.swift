// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct AppCoordinator: View, AppCoordinatorConforming {
    @Environment(IAPObservable.self)
    public var iapObservable

    @Environment(\.appConfiguration)
    private var appConfiguration

    private let profileObservable: ProfileObservable

    public let tunnel: TunnelObservable

    private let webReceiverObservable: WebReceiverObservable

    @State
    private var paywallReason: PaywallReason?

    @State
    private var paywallContinuation: (() -> Void)?

    @State
    private var interactiveObservable = InteractiveObservable()

    @State
    private var errorHandler: ErrorHandler = .default()

    public init(
        profileObservable: ProfileObservable,
        tunnel: TunnelObservable,
        webReceiverObservable: WebReceiverObservable
    ) {
        self.profileObservable = profileObservable
        self.tunnel = tunnel
        self.webReceiverObservable = webReceiverObservable
        pspLog(.core, .info, "AppCordinator (Observables)")
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
            profileObservable: profileObservable,
            webReceiverObservable: webReceiverObservable
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
            DebugLogView(withAppParameters: appConfiguration.constants.log) {
                DebugLogContentView(lines: $0)
            }
        case .tunnelLog:
            DebugLogView(withTunnel: tunnel) {
                DebugLogContentView(lines: $0)
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Handlers

extension AppCoordinator {
    public func onInteractiveLogin(_ profile: Profile, _ onComplete: @escaping InteractiveObservable.CompletionBlock) {
        pspLog(.core, .info, "Present interactive login")
        interactiveObservable.present(
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
        features: Set<ABI.AppFeature>,
        continuation: (() -> Void)?
    ) {
        pspLog(.core, .info, "Purchase required for features: \(features)")
        guard !iapObservable.isLoadingReceipt else {
            let V = Strings.Views.Paywall.Alerts.Verification.self
            pspLog(.core, .info, "Present verification alert")
            errorHandler.handle(
                title: Strings.Views.Paywall.Alerts.Confirmation.title,
                message: [
                    V.Connect._1,
                    V.boot,
                    "\n\n",
                    V.Connect._2(iapObservable.verificationDelayMinutes)
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
    AppCoordinator(
        profileObservable: .forPreviews,
        tunnel: .forPreviews,
        webReceiverObservable: .forPreviews
    )
    .withMockEnvironment()
}
