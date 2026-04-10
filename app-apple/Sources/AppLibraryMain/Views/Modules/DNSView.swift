// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import CommonLibrary
import SwiftUI

struct DNSView: View, ModuleDraftEditing {
    @Environment(Theme.self)
    private var theme

    @ObservedObject
    var draft: ModuleDraft<DNSModule.Builder>

    init(draft: ModuleDraft<DNSModule.Builder>) {
        self.draft = draft
    }

    var body: some View {
        debugChanges()
        return Group {
            protocolSection
            routingSection
            Group {
                serversSection
                domainsSection
            }
            .labelsHidden()
            domainsBehaviorSection
        }
        .moduleView(draft: draft)
    }
}

private extension DNSView {
    static let allProtocols: [DNSProtocol] = [
        .cleartext,
        .https,
        .tls
    ]

    var protocolSection: some View {
        Section {
            Picker(Strings.Global.Nouns.protocol, selection: $draft.module.protocolType) {
                ForEach(Self.allProtocols, id: \.self) {
                    Text($0.localizedDescription)
                }
            }
            switch draft.module.protocolType {
            case .cleartext:
                EmptyView()
            case .https:
                ThemeTextField(Strings.Unlocalized.url, text: $draft.module.dohURL, placeholder: Strings.Unlocalized.Placeholders.dohURL)
                    .labelsHidden()
            case .tls:
                ThemeTextField(Strings.Global.Nouns.hostname, text: $draft.module.dotHostname, placeholder: Strings.Unlocalized.Placeholders.dotHostname)
                    .labelsHidden()
            @unknown default:
                EmptyView()
            }
        }
    }

    var routingSection: some View {
        Picker(Strings.Modules.Dns.routeThroughVpn, selection: $draft.module.routesThroughVPN) {
            Text(Strings.Global.Nouns.default)
                .tag(nil as Bool?)
            Text(Strings.Global.Nouns.yes)
                .tag(true as Bool?)
            Text(Strings.Global.Nouns.no)
                .tag(false as Bool?)
        }
        .themeContainerWithSingleEntry(
            footer: Strings.Modules.Dns.RouteThroughVpn.footer)
    }

    var serversSection: some View {
        theme.listSection(
            Strings.Entities.Dns.servers,
            addTitle: Strings.Modules.Dns.Servers.add,
            originalItems: $draft.module.servers,
            itemLabel: {
                if $0 {
                    Text($1.wrappedValue)
                } else {
                    ThemeTextField(
                        "",
                        text: $1,
                        placeholder: Strings.Unlocalized.Placeholders.ipV4DNS,
                        inputType: .ipAddress
                    )
                }
            }
        )
    }

    var domainsSection: some View {
        theme.listSection(
            Strings.Entities.Dns.domains,
            addTitle: Strings.Modules.Dns.Domains.add,
            originalItems: $draft.module.domains ?? [],
            itemLabel: {
                if $0 {
                    Text($1.wrappedValue)
                } else {
                    ThemeTextField(
                        "",
                        text: $1,
                        placeholder: Strings.Unlocalized.Placeholders.hostname
                    )
                }
            }
        )
    }

    var domainsBehaviorSection: some View {
        let V = Strings.Entities.Dns.Domains.self
        return Group {
            Toggle(V.firstIsPrimary, isOn: $draft.module.isFirstDomainPrimary)
                .themeContainerEntry(subtitle: V.FirstIsPrimary.footer)
            Picker(V.useFor, selection: $draft.module.domainPolicy) {
                Text(V.UseFor.default)
                    .tag(nil as DNSModule.DomainPolicy?)
                Text(V.UseFor.match)
                    .tag(DNSModule.DomainPolicy.match)
                Text(V.UseFor.search)
                    .tag(DNSModule.DomainPolicy.search)
            }
            .themeContainerEntry(subtitle: V.UseFor.footer)
        }
        .themeContainer()
        .disabled(!hasNonEmptyDomains)
    }
}

private extension DNSView {
    var hasNonEmptyDomains: Bool {
        draft.module.domains?.contains { !$0.isEmpty } ?? false
    }
}

// MARK: - Previews

#Preview {
    var module = DNSModule.Builder()
    module.protocolType = .https
    module.servers = ["1.1.1.1", "2.2.2.2", "3.3.3.3"]
    module.dohURL = "https://doh.com/query"
    module.dotHostname = "tls.com"
    module.domains = ["one.com", "two.net", "three.com"]
    return module.preview()
}
