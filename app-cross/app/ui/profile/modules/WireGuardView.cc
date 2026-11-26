// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "WireGuardView.h"
#include "../../../strings/Unlocalized.h"
#include <wx/numformatter.h>

namespace Passepartout {
WireGuardView::WireGuardView(wxWindow *parent, const Partout::Models::WireGuardModule &module, OpenModuleContent open_content, const WireGuardKeyGenerator &wireguard_keygen,
    std::function<void(wxString, std::vector<std::string>)> open_list
)
    : ModuleDetailView(parent, std::move(open_content), Presentation::Form) {
    using namespace Strings::Unlocalized;
    if (!module.configuration) return;
    const auto &c = *module.configuration;
    const auto &local = c.interface_;
    const auto entries = [](const std::vector<std::string> &values) {
        const auto count = values.size();
        auto text = Localized(count == 1 ? StringKey::GlobalNounsEntriesOne : StringKey::GlobalNounsEntriesN);
        text.Replace("%d", wxNumberFormatter::ToString(static_cast<long>(count)));
        return text;
    };
    const auto list_row = [this, &entries, &open_list](StringKey label, const std::vector<std::string> &values) {
        if (!HasContent(values)) return;
        const auto title = Localized(label);
        const auto items = values;
        ContentLink(title, [open_list, title, items] {
            open_list(title, items);
        }, entries(values));
    };
    Section(Localized(StringKey::ModulesWireguardInterface));
    Row(StringKey::GlobalNounsPrivateKey, local.privateKey, true, std::nullopt, true);
    Row(StringKey::GlobalNounsPublicKey, wireguard_keygen.PublicKey(local.privateKey));
    list_row(StringKey::GlobalNounsAddresses, local.addresses);
    Row(MTU, local.mtu);
    if (local.dns.has_value()) {
        const auto &dns = *local.dns;
        Section(DNS);
        list_row(StringKey::GlobalNounsServers, dns.servers);
        std::vector<std::string> domains;
        if (dns.domainName) domains.push_back(*dns.domainName);
        if (dns.searchDomains) domains.insert(domains.end(), dns.searchDomains->begin(), dns.searchDomains->end());
        list_row(StringKey::EntitiesDnsSearchDomains, domains);
    }
    unsigned index = 0;
    for (const auto &peer : c.peers) {
        auto title = Localized(StringKey::ModulesWireguardPeer);
        title.Replace("%d", ValueText(++index));
        Section(title);
        Row(StringKey::GlobalNounsPublicKey, peer.publicKey, true);
        Row(StringKey::ModulesWireguardPresharedKey, peer.preSharedKey, true, std::nullopt, true);
        Row(StringKey::GlobalNounsEndpoint, peer.endpoint, true);
        list_row(StringKey::ModulesWireguardAllowedIps, peer.allowedIPs);
        Row(StringKey::GlobalNounsKeepAlive, peer.keepAlive);
    }
    Finish();
}
}
