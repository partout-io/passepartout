// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "WireGuardView.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
WireGuardView::WireGuardView(wxWindow *parent, const Partout::Models::WireGuardModule &module, OpenModuleContent openContent, const WireGuardKeyGenerator &keys)
    : ModuleDetailView(parent, std::move(openContent), Presentation::Form) {
    using namespace Strings::Unlocalized;
    if (!module.configuration) return;
    const auto c = module.configuration->ToJson();
    const auto local = c.at("interface");
    Section(Localized(StringKey::ModulesWireguardInterface));
    Row(StringKey::GlobalNounsPrivateKey, local.at("privateKey"), true);
    Row(StringKey::GlobalNounsPublicKey, keys.PublicKey(local.at("privateKey").get<std::string>()));
    Row(StringKey::GlobalNounsAddresses, local.value("addresses", nlohmann::json()), true);
    Row(MTU, local.value("mtu", nlohmann::json()));
    if (local.contains("dns") && local["dns"].is_object()) {
        const auto dns = local["dns"];
        Section(DNS);
        Row(StringKey::GlobalNounsServers, dns.value("servers", nlohmann::json()), true);
        nlohmann::json domains = nlohmann::json::array();
        if (dns.contains("domainName") && !dns["domainName"].is_null()) domains.push_back(dns["domainName"]);
        if (dns.contains("searchDomains") && dns["searchDomains"].is_array())
            for (const auto &domain : dns["searchDomains"]) domains.push_back(domain);
        Row(StringKey::EntitiesDnsSearchDomains, domains, true);
    }
    unsigned index = 0;
    for (const auto &peer : c.at("peers")) {
        auto title = Localized(StringKey::ModulesWireguardPeer);
        title.Replace("%d", ValueText(++index));
        Section(title);
        Row(StringKey::GlobalNounsPublicKey, peer.at("publicKey"), true);
        Row(StringKey::ModulesWireguardPresharedKey, peer.value("preSharedKey", nlohmann::json()), true);
        Row(StringKey::GlobalNounsEndpoint, peer.value("endpoint", nlohmann::json()), true);
        Row(StringKey::ModulesWireguardAllowedIps, peer.value("allowedIPs", nlohmann::json()), true);
        Row(StringKey::GlobalNounsKeepAlive, peer.value("keepAlive", nlohmann::json()));
    }
    Finish();
}
}
