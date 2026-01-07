// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

@available(*, deprecated, message: "#1594")
public struct LegacyAppCoordinator: View, LegacyAppCoordinatorConforming, SizeClassProviding {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    @EnvironmentObject
    public var iapManager: IAPManager

    @Environment(\.isUITesting)
    private var isUITesting

    @Environment(\.horizontalSizeClass)
    public var hsClass

    @Environment(\.verticalSizeClass)
    public var vsClass

    private let profileManager: ProfileManager

    public let tunnel: ExtendedTunnel

    private let registry: Registry

    private let webReceiverManager: WebReceiverManager

    @State
    private var isImportingFile = false

    @State
    private var paywallReason: PaywallReason?

    @State
    private var paywallContinuation: (() -> Void)?

    @State
    private var modalRoute: ModalRoute?

    @State
    private var confirmationAction: ConfirmationAction?

    @State
    private var profilePath = NavigationPath()

    @State
    private var migrationPath = NavigationPath()

    @State
    private var profileEditor = ProfileEditor()

    @State
    private var interactiveObservable = InteractiveObservable()

    @State
    private var errorHandler: ErrorHandler = .default()

    public init(
        profileManager: ProfileManager,
        tunnel: ExtendedTunnel,
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
        NavigationStack {
            contentView
                .toolbar(content: toolbarContent)
        }
        .modifier(OnboardingModifier(
            modalRoute: $modalRoute
        ))
        .modifier(DynamicPaywallModifier(
            paywallReason: $paywallReason,
            onEditProfile: onEditProfile,
            paywallContinuation: paywallContinuation
        ))
        .themeModal(
            item: $modalRoute,
            options: modalRoute?.options(),
            content: modalDestination
        )
        .themeConfirmation(
            isPresented: Binding(presenting: $confirmationAction, if: { $0 != nil }),
            title: Strings.Global.Actions.remove,
            isDestructive: true,
            action: confirmDeleteProfile
        )
        .withErrorHandler(errorHandler)
        .onChange(of: interactiveObservable.isPresented) {
            modalRoute = $0 ? .interactiveLogin : nil
        }
        .onReceive(AppPipe.settings) {
            guard modalRoute != .settings else {
                return
            }
            present(.settings)
        }
    }
}

// MARK: -

extension LegacyAppCoordinator {
    var contentView: some View {
        ProfileContainerView(
            layout: overriddenLayout,
            profileManager: profileManager,
            tunnel: tunnel,
            registry: registry,
            isImporting: $isImportingFile,
            errorHandler: errorHandler,
            flow: .init(
                onEditProfile: onEditProfile,
                onDeleteProfile: onDeleteProfile,
                connectionFlow: .init(
                    onConnect: {
                        await onConnect($0, force: false)
                    },
                    onProviderEntityRequired: {
                        onProviderEntityRequired($0, force: false)
                    }
                )
            )
        )
    }

    var overriddenLayout: ProfilesLayout {
        if isUITesting {
            return isBigDevice ? .grid : .list
        }
        guard isBigDevice else {
            return .list
        }
        return userPreferences.profilesLayout
    }

    func toolbarContent() -> some ToolbarContent {
        AppToolbar(
            profileManager: profileManager,
            registry: registry,
            layout: userPreferences.binding(\.profilesLayout),
            importAction: importActionBinding,
            onSettings: {
                present(.settings)
            },
            onNewProfile: onNewProfile
        )
    }

    @ViewBuilder
    func modalDestination(for item: ModalRoute?) -> some View {
        switch item {
        case .settings:
            SettingsCoordinator(
                profileManager: profileManager,
                tunnel: tunnel
            )
        case .editProfile:
            ProfileCoordinator(
                profileManager: profileManager,
                profileEditor: profileEditor,
                registry: registry,
                moduleViewFactory: LegacyModuleViewFactory(registry: registry),
                path: $profilePath,
                onDismiss: onDismiss
            )
        case .editProviderEntity(let profile, let force, let module):
            ProviderServerCoordinatorIfSupported(
                module: module,
                errorHandler: errorHandler,
                selectTitle: profile.providerServerSelectionTitle,
                onSelect: {
                    try await onSelectProviderEntity(with: $0, in: profile, force: force)
                }
            )
        case .importProfileQR:
#if os(iOS)
            QRScanView(
                isAvailable: .constant(true),
                onLoad: {
                    if $0 != nil {
                        modalRoute = .importProfileText
                    }
                },
                onDetect: {
                    importText($0)
                    modalRoute = nil
                }
            )
            .navigationTitle(Strings.Views.App.Toolbar.ImportQr.title)
            .themeNavigationDetail()
            .themeNavigationStack(closable: true)
#else
            // QR scanner shown on macOS?
            EmptyView()
#endif
        case .importProfileText:
            ThemeTextInputView(
                Strings.Views.App.Toolbar.ImportText.title,
                message: Strings.Views.App.Toolbar.ImportText.caption,
                monospaced: true,
                isPresented: Binding(presenting: $modalRoute) {
                    switch $0 {
                    case .importProfileText:
                        return true
                    default:
                        return false
                    }
                },
                onValidate: {
                    !$0.isEmpty
                },
                onSubmit: importText
            )
        case .interactiveLogin:
            InteractiveCoordinator(style: .modal, manager: interactiveObservable) {
                errorHandler.handle(
                    $0,
                    title: interactiveObservable.editor.profile.name,
                    message: Strings.Errors.App.tunnel
                )
            }
            .presentationDetents([.medium])
#if os(macOS)
        case .systemExtension:
            SystemExtensionView()
                .themeNavigationStack(closable: true, closeTitle: Strings.Global.Nouns.ok)
#endif
        default:
            EmptyView()
        }
    }

    var importActionBinding: Binding<AddProfileMenu.Action?> {
        Binding {
            if isImportingFile {
                return .importFile
            }
            switch modalRoute {
            case .importProfileQR:
                return .importQR
            case .importProfileText:
                return .importText
            default:
                return nil
            }
        } set: {
            switch $0 {
            case .importFile:
                isImportingFile = true
            case .importQR:
                modalRoute = .importProfileQR
            case .importText:
                modalRoute = .importProfileText
            default:
                modalRoute = nil
            }
        }
    }

    func importText(_ text: String) {
        Task {
            do {
                let filename = profileManager.firstUniqueName(
                    from: Strings.Placeholders.Profile.importedName
                )
                try await profileManager.legacyImport(
                    .contents(filename: filename, data: text),
                    registry: registry
                )
            } catch {
                pp_log_g(.App.profiles, .error, "Unable to import text: \(error)")
                errorHandler.handle(error, title: Strings.Global.Actions.import)
            }
        }
    }
}

// MARK: - Providers

private struct ProviderServerCoordinatorIfSupported: View {
    let module: Module

    let errorHandler: ErrorHandler

    let selectTitle: String

    let onSelect: (Module) async throws -> Void

    var body: some View {
        if let supporting = module as? ProviderModule {
            ProviderServerCoordinator(
                module: supporting,
                selectTitle: selectTitle,
                onSelect: {
                    var newBuilder = supporting.builder()
                    newBuilder.entity = $0
                    let newModule = try newBuilder.build()
                    try await onSelect(newModule)
                },
                errorHandler: errorHandler
            )
        } else {
            fatalError("Module got too far without being ProviderModule: \(module)")
        }
    }
}

// MARK: - Handlers

extension LegacyAppCoordinator {
    public func onInteractiveLogin(_ profile: Profile, _ onComplete: @escaping InteractiveObservable.CompletionBlock) {
        pp_log_g(.App.core, .info, "Present interactive login")
        interactiveObservable.present(with: ABI.AppProfile(native: profile), onComplete: onComplete)
    }

    public func onProviderEntityRequired(_ profile: Profile, force: Bool) {
        guard let module = profile.activeProviderModule else {
            assertionFailure("Editing provider entity, but profile has no selected provider module")
            return
        }
        pp_log_g(.App.core, .info, "Present provider entity selector")
        present(.editProviderEntity(profile, force, module))
    }

    public func onPurchaseRequired(
        for profile: Profile,
        features: Set<ABI.AppFeature>,
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
        if case ABI.AppError.systemExtension(let result) = error, result != .success {
            modalRoute = .systemExtension
            return
        }
        errorHandler.handle(
            error,
            title: title,
            message: Strings.Errors.App.tunnel
        )
    }
}

private extension LegacyAppCoordinator {
    func onSelectProviderEntity(with newModule: Module, in profile: Profile, force: Bool) async throws {

        // XXX: select entity after dismissing
        try await Task.sleep(for: .milliseconds(500))

        pp_log_g(.App.core, .info, "Select new provider entity: (profile=\(profile.id), module=\(newModule.id))")

        do {
            var builder = profile.builder()
            builder.saveModule(newModule)
            let newProfile = try builder.build()

            let wasConnected = tunnel.status(ofProfileId: newProfile.id) == .active
            try await profileManager.save(newProfile, isLocal: true)

            guard profile.shouldConnectToProviderServer else {
                return
            }

            if !wasConnected {
                pp_log_g(.App.core, .info, "Profile \(newProfile.id) was not connected, will connect to new provider entity")
                await onConnect(newProfile, force: force)
            } else {
                pp_log_g(.App.core, .info, "Profile \(newProfile.id) was connected, will reconnect to new provider entity via AppContext observation")
            }
        } catch {
            pp_log_g(.App.core, .error, "Unable to save new provider entity: \(error)")
            throw error
        }
    }

    func onNewProfile(_ profile: EditableProfile) {
        editProfile(profile)
    }

    func onEditProfile(_ preview: ABI.ProfilePreview) {
        guard let profile = profileManager.partoutProfile(withId: preview.id) else {
            return
        }
        editProfile(profile.editable())
    }

    func onDeleteProfile(_ preview: ABI.ProfilePreview) {
        confirmationAction = .deleteProfile(preview)
    }

    func confirmDeleteProfile() {
        guard case .deleteProfile(let profileBeingDeleted) = confirmationAction else {
            assertionFailure("No profile is being deleted")
            return
        }
        Task {
            await profileManager.remove(withId: profileBeingDeleted.id)
        }
    }

    func editProfile(_ profile: EditableProfile) {
        profilePath = NavigationPath()
        let isShared = profileManager.isRemotelyShared(profileWithId: profile.id)
        profileEditor.load(profile, isShared: isShared)
        present(.editProfile)
    }
}

private extension LegacyAppCoordinator {
    func present(_ route: ModalRoute?) {
        setLater(route) {
            modalRoute = $0
        }
    }

    func onDismiss() {
        present(nil)
    }
}

private extension Profile {
    var providerServerSelectionTitle: String {
        attributes.isAvailableForTV == true ? Strings.Views.Providers.selectEntity : Strings.Global.Actions.connect
    }

    var shouldConnectToProviderServer: Bool {
#if os(tvOS)
        true
#else
        // do not connect TV profiles on server selection
        attributes.isAvailableForTV != true
#endif
    }
}

// MARK: - Paywall

private struct DynamicPaywallModifier: ViewModifier {

    @Environment(ConfigObservable.self)
    private var configObservable

    @Binding
    var paywallReason: PaywallReason?

    let onEditProfile: (ABI.ProfilePreview) -> Void

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
