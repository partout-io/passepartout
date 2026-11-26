// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "DNSView.h"
#include "../../../strings/Unlocalized.h"

namespace Passepartout {
DNSView::DNSView(wxWindow *parent, const Partout::Models::DNSModule &module, OpenModuleContent open_content)
    : ModuleDetailView(parent, std::move(open_content), Presentation::Form) {
    using namespace Strings::Unlocalized;
    const auto &c = module;
    const bool cleartext = std::holds_alternative<Partout::Models::DNSModuleProtocolTypeCleartext>(c.protocolType);
    Section({});
    Row(StringKey::ModulesDnsPolicyInheritsVpn, module.inheritsVPN.value_or(false));
    if (module.routesThroughVPN) Row(StringKey::ModulesDnsPolicyRouteThroughVpn, *module.routesThroughVPN);
    else Field(Localized(StringKey::ModulesDnsPolicyRouteThroughVpn), Localized(StringKey::GlobalNounsDefault));
    Row(StringKey::ModulesDnsPolicyUseOnly, (module.inheritsVPN.value_or(false) || cleartext) &&
        module.domainPolicy && module.domainPolicy->value == Partout::Models::DNSModuleDomainPolicy::matchAndSearch);
    if (module.inheritsVPN.value_or(false)) {
        Finish();
        return;
    }
    Section(Localized(StringKey::ModulesDnsCustomSettingsHeader));
    std::visit([this](const auto &protocol) {
        using T = std::decay_t<decltype(protocol)>;
        if constexpr (std::is_same_v<T, Partout::Models::DNSModuleProtocolTypeHttps>) {
            Field(Localized(StringKey::GlobalNounsProtocol), Localized(StringKey::EntitiesDnsProtocolHttps));
            Row(URL, protocol.url);
        } else if constexpr (std::is_same_v<T, Partout::Models::DNSModuleProtocolTypeTls>) {
            Field(Localized(StringKey::GlobalNounsProtocol), Localized(StringKey::EntitiesDnsProtocolTls));
            Row(StringKey::GlobalNounsHostname, protocol.hostname);
        } else {
            Field(Localized(StringKey::GlobalNounsProtocol), Localized(StringKey::EntitiesDnsProtocolCleartext));
        }
    }, c.protocolType);
    Row(StringKey::EntitiesDnsServers, c.servers);
    if (cleartext) {
        std::vector<std::string> domains;
        if (module.domainName) domains.push_back(*module.domainName);
        if (module.searchDomains) for (const auto &domain : *module.searchDomains) domains.push_back(domain);
        Row(StringKey::EntitiesDnsDomains, domains);
        Row(StringKey::ModulesDnsDomainsFirstIsPrimary, module.domainName.has_value());
    }
    Finish();
}
}
