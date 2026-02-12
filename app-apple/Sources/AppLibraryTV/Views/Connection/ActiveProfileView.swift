// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import SwiftUI

struct ActiveProfileView: View {
    @Environment(Theme.self)
    private var theme

    @Environment(ProfileObservable.self)
    private var profileObservable

    @EnvironmentObject
    private var apiManager: APIManager

    let header: ABI.AppProfileHeader?

    let tunnel: TunnelObservable

    @Binding
    var isSwitching: Bool

    @FocusState.Binding
    var focusedField: ConnectionView.Field?

    let errorHandler: ErrorHandler

    var flow: ConnectionFlow?

    var body: some View {
        VStack(spacing: .zero) {
            VStack {
                VStack {
                    activeProfileView
                    statusView
                }
                .padding(.bottom)

                header.map {
                    detailView(for: $0)
                }
                .padding(.bottom)

                Group {
                    toggleConnectionButton
                    switchProfileButton
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 100)

            Spacer()
        }
    }
}

private extension ActiveProfileView {
    var activeProfileView: some View {
        Text(header?.name ?? Strings.Views.App.InstalledProfile.None.name)
            .font(.title)
            .fontWeight(theme.relevantWeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .uiAccessibility(.App.profilesHeader)
    }

    var statusView: some View {
        ConnectionStatusText(tunnel: tunnel, profileId: header?.id)
            .font(.title2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .brightness(0.2)
    }

    func detailView(for header: ABI.AppProfileHeader) -> some View {
        VStack(spacing: 10) {
            if let primaryType = header.localizedDescription(optionalStyle: .primaryType) {
                ListRowView(title: Strings.Global.Nouns.protocol) {
                    Text(primaryType)
                }
            }
            if let providerInfo = header.providerInfo {
                if let provider = apiManager.provider(withId: providerInfo.providerId) {
                    ListRowView(title: Strings.Global.Nouns.provider) {
                        Text(provider.description)
                    }
                }
                if let countryCode = providerInfo.countryCode {
                    ListRowView(title: Strings.Global.Nouns.country) {
                        ThemeCountryText(countryCode)
                    }
                }
            }
            if let secondaryTypes = header.localizedDescription(optionalStyle: .secondaryTypes) {
                ListRowView(title: secondaryTypes) {
                    EmptyView()
                }
            }
        }
        .font(.title3)
    }

    var toggleConnectionButton: some View {
        ActiveTunnelButton(
            tunnel: tunnel,
            header: header,
            focusedField: $focusedField,
            errorHandler: errorHandler,
            flow: flow
        )
        .focused($focusedField, equals: .connect)
    }

    var switchProfileButton: some View {
        Button {
            isSwitching.toggle()
        } label: {
            Text(Strings.Global.Actions.select)
                .frame(maxWidth: .infinity)
                .forMainButton(
                    withColor: .gray,
                    focused: focusedField == .switchProfile,
                    disabled: false
                )
        }
        .focused($focusedField, equals: .switchProfile)
    }
}

// MARK: - Previews

#Preview("Host") {
    let profile: Profile = {
        do {
            var moduleBuilder = OpenVPNModule.Builder()
            moduleBuilder.configurationBuilder = .init()
            moduleBuilder.configurationBuilder?.ca = .init(pem: "")
            moduleBuilder.configurationBuilder?.remotes = [
                try .init("1.2.3.4", .init(.tcp, 1234))
            ]
            let module = try moduleBuilder.build()

            let builder = Profile.Builder(
                name: "Host",
                modules: [module]
            )
            return try builder.build()
        } catch {
            fatalError(error.localizedDescription)
        }
    }()

    HStack {
        ContentPreview(header: profile.abiHeaderWithBogusFlagsAndRequirements())
            .frame(maxWidth: .infinity)
        VStack {}
            .frame(maxWidth: .infinity)
    }
}

#Preview("Provider") {
    let profile: Profile = {
        do {
            var moduleBuilder = ProviderModule.Builder()
            moduleBuilder.providerId = .mullvad
            moduleBuilder.providerModuleType = .openVPN
            let module = try moduleBuilder.build()

            let builder = Profile.Builder(
                name: "Provider",
                modules: [module]
            )
            return try builder.build()
        } catch {
            fatalError(error.localizedDescription)
        }
    }()

    HStack {
        ContentPreview(header: profile.abiHeaderWithBogusFlagsAndRequirements())
            .frame(maxWidth: .infinity)
        VStack {}
            .frame(maxWidth: .infinity)
    }
    .task {
        try? await APIManager.forPreviews.fetchIndex()
    }
}

private struct ContentPreview: View {
    let header: ABI.AppProfileHeader

    @State
    private var isSwitching = false

    @FocusState
    private var focusedField: ConnectionView.Field?

    var body: some View {
        ActiveProfileView(
            header: header,
            tunnel: .forPreviews,
            isSwitching: $isSwitching,
            focusedField: $focusedField,
            errorHandler: .default()
        )
        .withMockEnvironment()
    }
}
