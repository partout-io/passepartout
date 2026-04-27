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
            inheritsSection
            behaviorSection
            if draft.module.inheritsVPN != true {
                overrideGroup
            }
        }
        .moduleView(draft: draft)
    }
}

private extension DNSView {
    var behaviorSection: some View {
        Group {
            routesThroughPicker
                .themeContainerEntry(subtitle: Strings.Modules.Dns.Policy.RouteThroughVpn.footer)
            onlyInDomainsToggle
                .themeContainerEntry(subtitle: Strings.Modules.Dns.Policy.UseOnly.footer)
        }
        .themeContainer()
    }

    var routesThroughPicker: some View {
        Picker(Strings.Modules.Dns.Policy.routeThroughVpn, selection: $draft.module.routesThroughVPN) {
            Text(Strings.Global.Nouns.default)
                .tag(nil as Bool?)
            Text(Strings.Global.Nouns.yes)
                .tag(true as Bool?)
            Text(Strings.Global.Nouns.no)
                .tag(false as Bool?)
        }
    }

    var onlyInDomainsToggle: some View {
        Toggle(Strings.Modules.Dns.Policy.useOnly, isOn: bindingToOnlyInDomains)
            .disabled(!canApplyDomainPolicy)
    }

    var inheritsSection: some View {
        Toggle(Strings.Modules.Dns.Policy.inheritsVpn, isOn: $draft.module.inheritsVPN)
            .themeContainerWithSingleEntry(footer: Strings.Modules.Dns.Policy.InheritsVpn.footer)
    }

    var overrideGroup: some View {
        Group {
            protocolSection
            serversSection.labelsHidden()
            if draft.module.protocolType == .cleartext {
                domainsSection.labelsHidden()
                firstDomainToggle
            }
        }
    }

    var protocolSection: some View {
        Group {
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
        .themeSection(header: Strings.Modules.Dns.CustomSettings.header)
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

    var firstDomainToggle: some View {
        Toggle(Strings.Modules.Dns.Domains.firstIsPrimary, isOn: $draft.module.isFirstDomainPrimary)
            .themeContainerWithSingleEntry(footer: Strings.Modules.Dns.Domains.FirstIsPrimary.footer)
            .disabled(!hasNonEmptyDomains)
    }
}

private extension DNSView {
    static let allProtocols: [DNSProtocol] = [
        .cleartext,
        .https,
        .tls
    ]

    static let allPolicies: [DNSModule.DomainPolicy?] = [
        .matchAndSearch,
        nil
    ]

    var bindingToOnlyInDomains: Binding<Bool> {
        Binding {
            canApplyDomainPolicy ? draft.module.domainPolicy == .matchAndSearch : false
        } set: {
            draft.module.domainPolicy = $0 ? .matchAndSearch : nil
        }
    }

    var canApplyDomainPolicy: Bool {
        draft.module.inheritsVPN == true || draft.module.protocolType == .cleartext
    }

    var hasNonEmptyDomains: Bool {
        draft.module.inheritsVPN == true || draft.module.domains?.contains { !$0.isEmpty } ?? false
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
