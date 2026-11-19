// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "WireGuardView.h"
#include "../../strings/Unlocalized.h"
#include <wx/numformatter.h>

namespace Passepartout {
WireGuardView::WireGuardView(wxWindow *parent, const Partout::Models::WireGuardModule &module, OpenModuleContent openContent, const WireGuardKeyGenerator &keys,
    std::function<void(wxString, std::vector<std::string>)> openList)
    : ModuleDetailView(parent, std::move(openContent), Presentation::Form) {
    using namespace Strings::Unlocalized;
    if (!module.configuration) return;
    const auto c = module.configuration->ToJson();
    const auto local = c.at("interface");
    const auto entries = [](const nlohmann::json &values) {
        const auto count = values.is_array() ? values.size() : 0;
        auto text = Localized(count == 1 ? StringKey::GlobalNounsEntriesOne : StringKey::GlobalNounsEntriesN);
        text.Replace("%d", wxNumberFormatter::ToString(static_cast<long>(count)));
        return text;
    };
    const auto listRow = [this, &entries, &openList](StringKey label, const nlohmann::json &values) {
        if (!HasContent(values)) return;
        const auto title = Localized(label);
        const auto items = values.get<std::vector<std::string>>();
        ContentLink(title, [openList, title, items] {
            openList(title, items);
        }, entries(values));
    };
    Section(Localized(StringKey::ModulesWireguardInterface));
    Row(StringKey::GlobalNounsPrivateKey, local.at("privateKey"), true, std::nullopt, true);
    Row(StringKey::GlobalNounsPublicKey, keys.PublicKey(local.at("privateKey").get<std::string>()));
    Row(StringKey::GlobalNounsAddresses, local.value("addresses", nlohmann::json()), true, entries(local.value("addresses", nlohmann::json())));
    Row(MTU, local.value("mtu", nlohmann::json()));
    if (local.contains("dns") && local["dns"].is_object()) {
        const auto dns = local["dns"];
        Section(DNS);
        listRow(StringKey::GlobalNounsServers, dns.value("servers", nlohmann::json()));
        nlohmann::json domains = nlohmann::json::array();
        if (dns.contains("domainName") && !dns["domainName"].is_null()) domains.push_back(dns["domainName"]);
        if (dns.contains("searchDomains") && dns["searchDomains"].is_array())
            for (const auto &domain : dns["searchDomains"]) domains.push_back(domain);
        listRow(StringKey::EntitiesDnsSearchDomains, domains);
    }
    unsigned index = 0;
    for (const auto &peer : c.at("peers")) {
        auto title = Localized(StringKey::ModulesWireguardPeer);
        title.Replace("%d", ValueText(++index));
        Section(title);
        Row(StringKey::GlobalNounsPublicKey, peer.at("publicKey"), true);
        Row(StringKey::ModulesWireguardPresharedKey, peer.value("preSharedKey", nlohmann::json()), true, std::nullopt, true);
        Row(StringKey::GlobalNounsEndpoint, peer.value("endpoint", nlohmann::json()), true);
        Row(StringKey::ModulesWireguardAllowedIps, peer.value("allowedIPs", nlohmann::json()), true, entries(peer.value("allowedIPs", nlohmann::json())));
        Row(StringKey::GlobalNounsKeepAlive, peer.value("keepAlive", nlohmann::json()));
    }
    Finish();
}
}
