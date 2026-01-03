// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

// MARK: Credentials

extension ProviderView {
    struct OpenVPNCredentialsLink: View {
        var body: some View {
            ProfileLink(
                Strings.Modules.Openvpn.credentials,
                route: ProviderModule.Subroute.openVPNCredentials
            )
        }
    }

    struct OpenVPNCredentialsView: View {

        @EnvironmentObject
        private var apiManager: APIManager

        @ObservedObject
        var draft: ModuleDraft<ProviderModule.Builder>

        @State
        private var builder = OpenVPN.Credentials.Builder()

        @State
        private var providerCustomization: OpenVPN.ProviderCustomization?

        var body: some View {
            Form {
                accountSection
                guidanceSection
            }
            .themeForm()
            .navigationTitle(Strings.Modules.Openvpn.credentials)
            .onLoad(perform: onLoad)
            .onChange(of: builder) { _ in
                saveCredentials()
            }
        }
    }
}

private extension ProviderView.OpenVPNCredentialsView {
    var accountSection: some View {
        Group {
            ThemeTextField(Strings.Global.Nouns.username, text: $builder.username, placeholder: Strings.Placeholders.username)
                .textContentType(.username)

            if !ignoresPassword {
                ThemeSecureField(title: Strings.Global.Nouns.password, text: $builder.password, placeholder: Strings.Placeholders.secret)
                    .textContentType(.password)
                    .onSubmit(saveCredentials)
            }
        }
        .themeSection(footer: guidanceString)
    }

    var guidanceSection: some View {
        providerCustomization.map {
            $0.credentials.url.map {
                Link(Strings.Modules.Openvpn.Credentials.Guidance.link, destination: $0)
            }
        }
    }

    var guidanceString: String? {
        guard draft.module.providerId != nil else {
            return nil
        }
        switch providerCustomization?.credentials.purpose {
        case .specific:
            return Strings.Modules.Openvpn.Credentials.Guidance.specific
        default:
            return Strings.Modules.Openvpn.Credentials.Guidance.web
        }
    }

    var ignoresPassword: Bool {
        providerCustomization?.credentials.options?.contains(.noPassword) ?? false
    }

    func onLoad() {
        guard let providerId = draft.module.providerId,
              let provider = apiManager.provider(withId: providerId) else {
            return
        }
        do {
            if let options: OpenVPNProviderTemplate.Options = try draft.module.options(for: .openVPN),
               let credentials = options.credentials {
                builder = credentials.builder()
            }
        } catch {
            pp_log_g(.App.core, .error, "Unable to load OpenVPN credentials from options: \(error)")
        }
        let metadata = provider.metadata(for: OpenVPNModule.self)
        providerCustomization = OpenVPN.ProviderCustomization(userInfo: metadata?.userInfo)
    }

    func saveCredentials() {
        do {
            var options: OpenVPNProviderTemplate.Options = try draft.module.options(for: .openVPN) ?? .init()
            options.credentials = builder.build()
            try draft.module.setOptions(options, for: .openVPN)
        } catch {
            pp_log_g(.App.core, .error, "Unable to store OpenVPN credentials to options: \(error)")
        }
    }
}

// MARK: - Configuration

extension ProviderView {
    struct OpenVPNConfigurationView: View {
        let configuration: OpenVPN.Configuration.Builder

        var body: some View {
            Form {
                NavigationLink(
                    destination: remotesDestination,
                    label: remotesLinkLabel
                )
                .themeSection(header: Strings.Global.Nouns.connection)

                OpenVPNView.ConfigurationView(
                    isServerPushed: false,
                    configuration: .constant(configuration)
                )
            }
            .themeForm()
            .navigationTitle(Strings.Global.Nouns.configuration)
        }
    }
}

private extension ProviderView.OpenVPNConfigurationView {
    func remotesLinkLabel() -> some View {
        ThemeRow(
            Strings.Modules.Openvpn.remotes,
            value: configuration.remotes?.count.localizedEntries
        )
    }

    func remotesDestination() -> some View {
        Form {
            ForEach(configuration.remotes ?? [], id: \.rawValue) {
                EndpointCardView(endpoint: $0)
            }
        }
        .themeForm()
        .navigationTitle(Strings.Modules.Openvpn.remotes)
    }
}
