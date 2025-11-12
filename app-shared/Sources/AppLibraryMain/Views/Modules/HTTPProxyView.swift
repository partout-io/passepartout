// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import SwiftUI

struct HTTPProxyView: View, ModuleDraftEditing {

    @EnvironmentObject
    private var theme: Theme

    @ObservedObject
    var draft: ModuleDraft<HTTPProxyModule.Builder>

    init(draft: ModuleDraft<HTTPProxyModule.Builder>, parameters: ModuleViewParameters) {
        self.draft = draft
    }

    var body: some View {
        Group {
            httpSection
            httpsSection
            pacSection
            bypassSection
        }
        .labelsHidden()
        .moduleView(draft: draft)
    }
}

private extension HTTPProxyView {
    var httpSection: some View {
        Group {
            ThemeTextField(
                Strings.Global.Nouns.address,
                text: $draft.module.address,
                placeholder: Strings.Unlocalized.Placeholders.proxyIPv4Address,
                inputType: .ipAddress
            )
            ThemeTextField(
                Strings.Global.Nouns.port,
                text: $draft.module.port.toString(omittingZero: true),
                placeholder: Strings.Unlocalized.Placeholders.proxyPort,
                inputType: .number
            )
        }
        .themeSection(header: Strings.Unlocalized.http)
    }

    var httpsSection: some View {
        Group {
            ThemeTextField(
                Strings.Global.Nouns.address,
                text: $draft.module.secureAddress,
                placeholder: Strings.Unlocalized.Placeholders.proxyIPv4Address,
                inputType: .ipAddress
            )
            ThemeTextField(
                Strings.Global.Nouns.port,
                text: $draft.module.securePort.toString(omittingZero: true),
                placeholder: Strings.Unlocalized.Placeholders.proxyPort,
                inputType: .number
            )
        }
        .themeSection(header: Strings.Unlocalized.https)
    }

    var pacSection: some View {
        Group {
            ThemeTextField(Strings.Unlocalized.url, text: $draft.module.pacURLString, placeholder: Strings.Unlocalized.Placeholders.pacURL)
        }
        .themeSection(header: Strings.Unlocalized.pac)
    }

    @ViewBuilder
    var bypassSection: some View {
        theme.listSection(
            Strings.Entities.HttpProxy.bypassDomains,
            addTitle: Strings.Modules.HttpProxy.BypassDomains.add,
            originalItems: $draft.module.bypassDomains,
            itemLabel: {
                if $0 {
                    Text($1.wrappedValue)
                } else {
                    ThemeTextField("", text: $1, placeholder: Strings.Unlocalized.Placeholders.hostname)
                }
            }
        )
    }
}

#Preview {
    var module = HTTPProxyModule.Builder()
    module.address = "10.10.10.10"
    module.port = 1080
    module.secureAddress = "20.20.20.20"
    module.securePort = 8080
    module.pacURLString = "http://proxy-pac.url"
    module.bypassDomains = ["bypass-one.com", "two-bypass.net"]
    return module.preview()
}
