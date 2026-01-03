// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public struct OpenVPNCredentialsGroup: View {
    private enum Field: Hashable {
        case username

        case password

        case otp
    }

    @EnvironmentObject
    private var iapManager: IAPManager

    @EnvironmentObject
    private var apiManager: APIManager

    @Environment(\.appConfiguration)
    private var appConfiguration

    @ObservedObject
    private var draft: ModuleDraft<OpenVPNModule.Builder>

    private let isAuthenticating: Bool

    private let onSubmit: (() -> Void)?

    @State
    private var builder = OpenVPN.Credentials.Builder()

    @State
    private var paywallReason: PaywallReason?

    @FocusState
    private var focusedField: Field?

    public init(
        draft: ModuleDraft<OpenVPNModule.Builder>,
        isAuthenticating: Bool = false,
        onSubmit: (() -> Void)? = nil
    ) {
        self.draft = draft
        self.isAuthenticating = isAuthenticating
        self.onSubmit = onSubmit
    }

    public var body: some View {
        debugChanges()
        return Group {
#if !os(tvOS)
            interactiveSection
#endif
            inputSection
        }
        .themeAnimation(on: draft.module.isInteractive, category: .modules)
        .themeAnimation(on: builder, category: .modules)
        .onLoad(perform: onLoad)
        .onChange(of: builder, perform: onChange)
        .modifier(ModuleDynamicPaywallModifier(reason: $paywallReason))
    }
}

private extension OpenVPNCredentialsGroup {
    var interactiveSection: some View {
        Group {
            Toggle(isOn: $draft.module.isInteractive) {
                HStack {
                    Text(Strings.Modules.Openvpn.Credentials.interactive)
                    PurchaseRequiredView(
                        requiring: requiredFeatures,
                        reason: $paywallReason
                    )
                }
            }
            .themeContainerEntry(subtitle: Strings.Modules.Openvpn.Credentials.Interactive.footer)

            if appConfiguration.distributionTarget.supportsPaidFeatures &&
                draft.module.isInteractive && !isAuthenticating {
                Picker(Strings.Unlocalized.otp, selection: $builder.otpMethod) {
                    ForEach(otpMethods, id: \.self) {
                        Text($0.localizedDescription(style: .entity))
                    }
                }
                .themeContainerEntry(subtitle: builder.otpMethod.localizedDescription(style: .approachDescription).nilIfEmpty)
            }
        }
        .themeContainer()
    }

    var inputSection: some View {
        Group {
            if !isAuthenticating || builder.otpMethod == .none {
                usernameField
                passwordField
            }
            if isAuthenticating, builder.otpMethod != .none {
                otpField
            }
        }
        .themeSection(footer: inputFooter)
    }

    var inputFooter: String? {
        if isAuthenticating {
            return builder.otpMethod.localizedDescription(style: .approachDescription)
                .nilIfEmpty
        }
        return nil
    }

    var usernameField: some View {
        ThemeTextField(Strings.Global.Nouns.username, text: $builder.username, placeholder: Strings.Placeholders.username)
            .textContentType(.username)
            .focused($focusedField, equals: .username)
    }

    var passwordField: some View {
        ThemeSecureField(title: Strings.Global.Nouns.password, text: $builder.password, placeholder: Strings.Placeholders.secret)
            .textContentType(.password)
            .focused($focusedField, equals: .password)
            .onSubmit {
                if builder.otpMethod == .none {
                    onSubmit?()
                }
            }
    }

    var otpField: some View {
        ThemeSecureField(
            title: Strings.Unlocalized.otp,
            text: $builder.otp ?? "",
            placeholder: Strings.Placeholders.secret
        )
        .textContentType(.oneTimeCode)
        .focused($focusedField, equals: .otp)
        .onSubmit {
            if builder.otpMethod != .none {
                onSubmit?()
            }
        }
    }
}

private extension OpenVPNCredentialsGroup {
    var requiredFeatures: Set<ABI.AppFeature>? {
        draft.module.isInteractive && builder.otpMethod != .none ? [.otp] : nil
    }

    var otpMethods: [OpenVPN.Credentials.OTPMethod] {
        [.none, .append, .encode]
    }

    func onLoad() {
        builder = draft.module.credentials?.builder() ?? OpenVPN.Credentials.Builder()
        builder.otp = nil
        if isAuthenticating {
            switch builder.otpMethod {
            case .none:
                focusedField = .username
            default:
                focusedField = .otp
            }
        }
    }

    func onChange(_ builder: OpenVPN.Credentials.Builder) {
        draft.module.credentials = builder.build()
    }
}

// MARK: - Previews

#Preview {
    let module = OpenVPNModule.Builder()
    let editor = ProfileEditor(modules: [module])

    struct ContentView: View {
        let editor: ProfileEditor

        let module: OpenVPNModule.Builder

        var body: some View {
            NavigationStack {
                OpenVPNCredentialsGroup(
                    draft: editor[module]
                )
            }
        }
    }

    return ContentView(editor: editor, module: module)
        .withMockEnvironment()
}
