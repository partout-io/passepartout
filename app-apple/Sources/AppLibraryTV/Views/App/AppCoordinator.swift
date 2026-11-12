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

    @State
    private var showsImporter = false

    @FocusState
    private var isImportFocused: Bool

    public init(
        profileObservable: ProfileObservable,
        tunnel: TunnelObservable,
        webReceiverObservable: WebReceiverObservable
    ) {
        self.profileObservable = profileObservable
        self.tunnel = tunnel
        self.webReceiverObservable = webReceiverObservable
        pspLog(.app, .info, "AppCordinator (Observables)")
    }

    public var body: some View {
        debugChanges()
        return NavigationStack {
            TabView {
                Group {
                    if profileObservable.hasProfiles {
                        connectionView
                    } else {
                        emptyProfilesView
                    }
                }.tabItem {
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
    var emptyProfilesView: some View {
        HStack {
            VStack {
                Text(Strings.Views.App.Folders.noProfiles)
                    .font(.title)
                Text(Strings.Views.Tv.ConnectionProfiles.webImportDescription)
                    .font(.body)
                    .padding(.vertical)
                    .fixedSize(horizontal: false, vertical: true)
                Button(showsImporter ? Strings.Global.Actions.cancel : Strings.Views.Tv.Profiles.importLocal) {
                    if showsImporter {
                        showsImporter = false
                        return
                    }
                    do {
                        try webReceiverObservable.start()
                        showsImporter = true
                    } catch {
                        errorHandler.handle(error)
                    }
                }
                .focused($isImportFocused)
            }
            .frame(maxWidth: .infinity)

            VStack {
                if showsImporter {
                    WebReceiverView(
                        webReceiverObservable: webReceiverObservable,
                        profileObservable: profileObservable,
                        errorHandler: errorHandler
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themeGradient()
        .defaultFocus($isImportFocused, true)
        .onDisappear {
            showsImporter = false
        }
    }

    var connectionView: some View {
        ConnectionView(
            profileObservable: profileObservable,
            tunnel: tunnel,
            interactiveObservable: interactiveObservable,
            errorHandler: errorHandler,
            flow: .init(
                onConnect: {
                    guard let profile = profileObservable.profile(withId: $0.id) else {
                        pspLog(.profiles, .error, "Unable to find profile from header: \($0.id)")
                        return
                    }
                    await onConnect(profile, force: false)
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
        pspLog(.app, .info, "Present interactive login")
        interactiveObservable.present(
            with: profile,
            onComplete: onComplete
        )
    }

    public func onPurchaseRequired(
        for profile: Profile,
        features: Set<ABI.AppFeature>,
        continuation: (() -> Void)?
    ) {
        pspLog(.purchases, .info, "Purchase required for features: \(features)")
        guard !iapObservable.isLoadingReceipt else {
            let V = Strings.Views.Paywall.Alerts.Verification.self
            pspLog(.purchases, .info, "Present verification alert")
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
        pspLog(.purchases, .info, "Present paywall")
        paywallContinuation = continuation

        setLater(.init(profile, requiredFeatures: features, action: .connect)) {
            paywallReason = $0
        }
    }

    public func onInfo(title: String, message: String) {
        errorHandler.handle(title: title, message: message)
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
