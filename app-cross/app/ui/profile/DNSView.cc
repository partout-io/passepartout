// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "DNSView.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
DNSView::DNSView(wxWindow *parent, const Partout::Models::DNSModule &module, OpenModuleContent openContent)
    : ModuleDetailView(parent, std::move(openContent)) {
    using namespace Strings::Unlocalized;
    const auto c = module.ToJson();
    const auto protocol = c.at("protocolType");
    const auto type = protocol.at("type").get<std::string>();
    Row(StringKey::ModulesDnsPolicyInheritsVpn, module.inheritsVPN.value_or(false));
    if (module.routesThroughVPN) Row(StringKey::ModulesDnsPolicyRouteThroughVpn, *module.routesThroughVPN);
    else Field(Localized(StringKey::ModulesDnsPolicyRouteThroughVpn), Localized(StringKey::GlobalNounsDefault));
    Row(StringKey::ModulesDnsPolicyUseOnly, (module.inheritsVPN.value_or(false) || type == "cleartext") &&
        module.domainPolicy && module.domainPolicy->ToJson() == "matchAndSearch");
    if (module.inheritsVPN.value_or(false)) {
        Finish();
        return;
    }
    Section(Localized(StringKey::ModulesDnsCustomSettingsHeader));
    Field(Localized(StringKey::GlobalNounsProtocol), Localized(type == "https" ? StringKey::EntitiesDnsProtocolHttps :
        type == "tls" ? StringKey::EntitiesDnsProtocolTls : StringKey::EntitiesDnsProtocolCleartext));
    Row(URL, protocol.value("url", nlohmann::json()));
    Row(StringKey::GlobalNounsHostname, protocol.value("hostname", nlohmann::json()));
    Row(StringKey::EntitiesDnsServers, c.at("servers"));
    if (type == "cleartext") {
        nlohmann::json domains = nlohmann::json::array();
        if (module.domainName) domains.push_back(*module.domainName);
        if (module.searchDomains) for (const auto &domain : *module.searchDomains) domains.push_back(domain);
        Row(StringKey::EntitiesDnsDomains, domains);
        Row(StringKey::ModulesDnsDomainsFirstIsPrimary, module.domainName.has_value());
    }
    Finish();
}
}
