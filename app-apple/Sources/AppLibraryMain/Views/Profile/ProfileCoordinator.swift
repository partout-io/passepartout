// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileCoordinator: View {
    struct Flow {
        let onNewModule: (ModuleType) -> Void

        let onSaveProfile: () async throws -> Void

        let onCancelEditing: () -> Void

        let onSendToTV: () -> Void
    }

    @Environment(Theme.self)
    private var theme

    @Environment(IAPObservable.self)
    private var iapObservable

    @EnvironmentObject
    private var preferencesManager: PreferencesManager

    @Environment(ConfigObservable.self)
    private var configObservable

    @Environment(RegistryObservable.self)
    private var registryObservable

    let profileObservable: ProfileObservable

    let profileEditor: ProfileEditor

    let moduleViewFactory: any ModuleViewFactory

    @Binding
    var path: NavigationPath

    let onDismiss: () -> Void

    @State
    private var modalRoute: ModalRoute?

    @State
    private var paywallReason: PaywallReason?

    @State
    private var errorHandler: ErrorHandler = .default()

    var body: some View {
        contentView
            .modifier(DynamicPaywallModifier(
                configObservable: configObservable,
                paywallReason: $paywallReason
            ))
            .themeModal(item: $modalRoute, content: modalDestination)
            .environment(\.dismissProfile, onDismiss)
            .withErrorHandler(errorHandler)
    }
}

// MARK: - Destinations

private extension ProfileCoordinator {
    var contentView: some View {
#if os(iOS)
        ProfileEditView(
            profileObservable: profileObservable,
            profileEditor: profileEditor,
            moduleViewFactory: moduleViewFactory,
            path: $path,
            paywallReason: $paywallReason,
            errorHandler: errorHandler,
            flow: flow
        )
        .themeNavigationDetail()
        .themeNavigationStack(path: $path)
#else
        ProfileSplitView(
            profileObservable: profileObservable,
            profileEditor: profileEditor,
            moduleViewFactory: moduleViewFactory,
            paywallReason: $paywallReason,
            errorHandler: errorHandler,
            flow: flow
        )
#endif
    }
}

private extension ProfileCoordinator {
    enum ModalRoute: Identifiable {
        case sendToTV(Profile)

        var id: Int {
            switch self {
            case .sendToTV: 1
            }
        }
    }

    @ViewBuilder
    func modalDestination(for item: ModalRoute) -> some View {
        switch item {
        case .sendToTV(let profile):
            SendToTVCoordinator(
                profile: profile,
                isPresented: Binding(presenting: $modalRoute) {
                    switch $0 {
                    case .sendToTV:
                        return true
                    default:
                        return false
                    }
                }
            )
        }
    }

    var flow: Flow {
        Flow(
            onNewModule: addNewModule,
            onSaveProfile: {
                try await saveProfile()
            },
            onCancelEditing: cancelEditing,
            onSendToTV: sendProfileToTV
        )
    }
}

// MARK: - Actions

private extension ProfileCoordinator {
    func addNewModule(_ moduleType: ModuleType) {
        let module = registryObservable.newModule(ofType: moduleType)
        withAnimation(theme.animation(for: .modules)) {
            profileEditor.saveModule(module, activating: true)
        }
    }

    @discardableResult
    func commitEditing(
        action: PaywallAction,
        dismissing: Bool
    ) async throws -> Profile? {
        do {
            let savedProfile = try await profileEditor.save(
                to: profileObservable,
                buildingWith: registryObservable,
                verifyingWith: iapObservable,
                preferencesManager: preferencesManager
            )
            if dismissing {
                onDismiss()
            }
            return savedProfile.native
        } catch ABI.AppError.verificationReceiptIsLoading {
            pspLog(.profiles, .error, "Unable to commit profile: loading receipt")
            let V = Strings.Views.Paywall.Alerts.self
            errorHandler.handle(
                title: V.Confirmation.title,
                message: [V.Verification.edit, V.Verification.boot].joined(separator: "\n\n")
            )
            return nil
        } catch ABI.AppError.verificationRequiredFeatures(let requiredFeatures) {
            pspLog(.profiles, .error, "Unable to commit profile: required features \(requiredFeatures)")
            let nextReason = PaywallReason(
                nil,
                requiredFeatures: requiredFeatures,
                action: action
            )
            setLater(nextReason) {
                paywallReason = $0
            }
            return nil
        } catch {
            pspLog(.profiles, .fault, "Unable to commit profile: \(error)")
            throw error
        }
    }

    func cancelEditing() {
        profileEditor.discard()
        onDismiss()
    }
}

private extension ProfileCoordinator {
    func saveProfile() async throws {
        do {
            try await commitEditing(
                action: paywallOtherAction,
                dismissing: true
            )
        } catch {
            errorHandler.handle(error, title: Strings.Global.Actions.save)
            throw error
        }
    }

    func sendProfileToTV() {
        Task {
            do {
                let profile = try await profileEditor.save(
                    to: nil,
                    buildingWith: registryObservable,
                    verifyingWith: nil,
                    preferencesManager: preferencesManager
                )
                modalRoute = .sendToTV(profile.native)
            } catch {
                errorHandler.handle(error, title: Strings.Views.Profile.SendTv.title_compound)
            }
        }
    }
}

// MARK: - Paywall

private struct DynamicPaywallModifier: ViewModifier {
    let configObservable: ConfigObservable

    @Binding
    var paywallReason: PaywallReason?

    func body(content: Content) -> some View {
        if configObservable.isUsingObservables {
            content.modifier(newModifier)
        } else {
            content.modifier(legacyModifier)
        }
    }

    var newModifier: some ViewModifier {
        PaywallModifier(
            reason: $paywallReason,
            onAction: { action, _ in
                switch action {
                case .cancel:
                    break
                default:
                    assertionFailure("Unhandled paywall action \(action)")
                }
            }
        )
    }

    var legacyModifier: some ViewModifier {
        LegacyPaywallModifier(
            reason: $paywallReason,
            onAction: { action, _ in
                switch action {
                case .cancel:
                    break
                default:
                    assertionFailure("Unhandled paywall action \(action)")
                }
            }
        )
    }
}

private extension ProfileCoordinator {
    var paywallOtherAction: PaywallAction {
        .cancel
    }
}

// MARK: - Previews

#Preview {
    ProfileCoordinator(
        profileObservable: .forPreviews,
        profileEditor: ProfileEditor(profile: .newMockProfile()),
        moduleViewFactory: DefaultModuleViewFactory(),
        path: .constant(NavigationPath()),
        onDismiss: {}
    )
    .withMockEnvironment()
}
