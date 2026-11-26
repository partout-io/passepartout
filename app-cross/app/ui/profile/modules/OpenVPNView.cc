// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "OpenVPNView.h"
#include "../../../strings/Unlocalized.h"
#include <algorithm>
#include <wx/base64.h>
#include <wx/numformatter.h>

namespace {
wxString HexKey(const std::string &value) {
    const auto decoded = wxBase64Decode(wxString::FromUTF8(value));
    const auto *bytes = static_cast<const unsigned char *>(decoded.GetData());
    wxString text;
    constexpr char hex[] = "0123456789abcdef";
    for (std::size_t i = 0; i < decoded.GetDataLen(); ++i) {
        text += hex[bytes[i] >> 4];
        text += hex[bytes[i] & 15];
    }
    return text;
}
}

using Passepartout::OpenVPNView;

OpenVPNView::OpenVPNView(wxWindow *parent, const Partout::Models::OpenVPNModule &module,
    OpenModuleContent open_content, std::function<void()> open_credentials, std::function<void()> open_remotes)
    : ModuleDetailView(parent, std::move(open_content), Presentation::Form) {
    using namespace Strings::Unlocalized;
    if (!module.configuration) return;
    const auto &c = *module.configuration;
    if (HasContent(c.remotes)) {
        Section(Localized(StringKey::GlobalNounsConnection));
        const auto count = module.configuration->remotes->size();
        auto summary = Localized(count == 1 ? StringKey::GlobalNounsEntriesOne : StringKey::GlobalNounsEntriesN);
        summary.Replace("%d", wxNumberFormatter::ToString(static_cast<long>(count)));
        ContentLink(Localized(StringKey::ModulesOpenvpnRemotes), std::move(open_remotes), summary);
    }
    if (module.configuration->authUserPass.value_or(false)) {
        Section(Localized(StringKey::GlobalNounsAccount));
        ContentLink(Localized(StringKey::ModulesOpenvpnCredentials), std::move(open_credentials));
    }
    using PullMask = Partout::Models::OpenVpnPullMask;
    std::vector<wxString> pulled;
    for (const auto &entry : std::vector<std::pair<PullMask::eOpenVpnPullMask, wxString>>{
        {PullMask::routes, Localized(StringKey::GlobalNounsRoutes)}, {PullMask::dns, DNS}, {PullMask::proxy, Proxy}}) {
        if (!c.noPullMask || std::none_of(c.noPullMask->begin(), c.noPullMask->end(), [&](const auto &mask) {
            return mask.value == entry.first;
        })) pulled.push_back(entry.second);
    }
    if (!pulled.empty()) {
        Section(Localized(StringKey::ModulesOpenvpnPull));
        std::sort(pulled.begin(), pulled.end());
        for (const auto &title : pulled) Field(title, Localized(StringKey::GlobalNounsEnabled));
    }
    using RoutingPolicy = Partout::Models::OpenVpnRoutingPolicy;
    const auto has_policy = [&](RoutingPolicy::eOpenVpnRoutingPolicy policy) {
        return c.routingPolicies && std::any_of(c.routingPolicies->begin(), c.routingPolicies->end(), [&](const auto &item) {
            return item.value == policy;
        });
    };
    if (has_policy(RoutingPolicy::IPv4) || has_policy(RoutingPolicy::IPv6)) {
        Section(Localized(StringKey::ModulesOpenvpnRedirectGateway));
        if (has_policy(RoutingPolicy::IPv4)) Field(IPv4, Localized(StringKey::GlobalNounsEnabled));
        if (has_policy(RoutingPolicy::IPv6)) Field(IPv6, Localized(StringKey::GlobalNounsEnabled));
    }
    IP(IPv4, c.ipv4, c.routes4, true);
    IP(IPv6, c.ipv6, c.routes6, true);
    if (HasContent(c.dnsServers) || HasContent(c.dnsDomain) || HasContent(c.searchDomains)) {
        Section(DNS);
        Row(StringKey::GlobalNounsServers, c.dnsServers);
        Row(StringKey::GlobalNounsDomain, c.dnsDomain);
        Row(StringKey::EntitiesDnsSearchDomains, c.searchDomains);
    }
    if (HasContent(c.httpProxy) || HasContent(c.httpsProxy) ||
        HasContent(c.proxyAutoConfigurationURL) || HasContent(c.proxyBypassDomains)) {
        Section(Proxy);
        Row(HTTP, c.httpProxy);
        Row(HTTPS, c.httpsProxy);
        Row(PAC, c.proxyAutoConfigurationURL);
        Row(StringKey::EntitiesHttpProxyBypassDomains, c.proxyBypassDomains);
    }
    if (HasContent(c.dataCiphers) || c.cipher.has_value() || c.digest.has_value() || c.xorMethod.has_value()) {
        Section(Localized(StringKey::ModulesOpenvpnCommunication));
        // The models API supplies canonical protocol spellings.
        if (c.dataCiphers.has_value()) {
            std::string ciphers;
            for (const auto &cipher : *c.dataCiphers) {
                if (!ciphers.empty()) ciphers += ':';
                ciphers += cipher.ToString();
            }
            Row(StringKey::ModulesOpenvpnDataCiphers, ciphers, true);
        }
        Field(Localized(StringKey::ModulesOpenvpnCipher), c.cipher ? ValueText(c.cipher->ToString()) : wxString{});
        Field(Localized(StringKey::ModulesOpenvpnDigest), c.digest ? ValueText(c.digest->ToString()) : wxString{});
        if (c.xorMethod) {
            std::visit([this](const auto &method) {
                using T = std::decay_t<decltype(method)>;
                auto text = ValueText(method.type);
                if constexpr (std::is_same_v<T, Partout::Models::OpenVpnObfuscationMethodObfuscate> ||
                    std::is_same_v<T, Partout::Models::OpenVpnObfuscationMethodXormask>) {
                    const auto mask = HexKey(method.mask);
                    if (!mask.empty()) text += " " + mask;
                }
                Row(XOR, text.ToStdString(wxConvUTF8), true, ValueText(method.type));
            }, *c.xorMethod);
        }
    }
    if (c.compressionFraming.has_value() || c.compressionAlgorithm.has_value()) {
        Section(Localized(StringKey::ModulesOpenvpnCompression));
        // These enums serialize as integers; presentation follows the typed values.
        if (const auto framing = module.configuration->compressionFraming) {
            Field(Localized(StringKey::ModulesOpenvpnCompressionFraming),
                framing->value == Partout::Models::OpenVpnCompressionFraming::disabled
                    ? Localized(StringKey::GlobalNounsDisabled)
                    : wxString(framing->value == Partout::Models::OpenVpnCompressionFraming::compLZO ? CompLZO : Compress));
        }
        if (const auto algorithm = module.configuration->compressionAlgorithm) {
            Field(Localized(StringKey::ModulesOpenvpnCompressionAlgorithm),
                algorithm->value == Partout::Models::OpenVpnCompressionAlgorithm::disabled
                    ? Localized(StringKey::GlobalNounsDisabled)
                    : algorithm->value == Partout::Models::OpenVpnCompressionAlgorithm::LZO
                        ? wxString(LZO) : Localized(StringKey::EntitiesOpenvpnCompressionAlgorithmOther));
        }
    }
    if (HasContent(c.ca) || HasContent(c.clientCertificate) || HasContent(c.clientKey) || c.tlsWrap.has_value()) {
        Section(TLS);
        Row(CA, c.ca, true, std::nullopt, true);
        Row(StringKey::GlobalNounsCertificate, c.clientCertificate, true, std::nullopt, true);
        Row(StringKey::GlobalNounsKey, c.clientKey, true, std::nullopt, true);
        if (c.tlsWrap) {
            const auto key = HexKey(c.tlsWrap->key.data);
            if (!key.empty()) {
                const auto title = Localized(StringKey::ModulesOpenvpnTlsWrap);
                LongContent(title, key, [this, title, key] {
                    open_content_(title, key);
                }, true);
            }
        }
        Row(StringKey::ModulesOpenvpnEku, module.configuration->checksEKU.value_or(false));
    }
    if (HasContent(c.keepAliveInterval) || HasContent(c.keepAliveTimeout)) {
        Section(Localized(StringKey::GlobalNounsKeepAlive));
        Duration(StringKey::GlobalNounsInterval, c.keepAliveInterval);
        Duration(StringKey::GlobalNounsTimeout, c.keepAliveTimeout);
    }
    if (HasContent(c.renegotiatesAfter) || HasContent(c.randomizeEndpoint) || HasContent(c.randomizeHostnames)) {
        Section(Localized(StringKey::GlobalNounsOther));
        Duration(StringKey::ModulesOpenvpnRenegotiation, c.renegotiatesAfter);
        Row(StringKey::ModulesOpenvpnRandomizeEndpoint, c.randomizeEndpoint);
        Row(StringKey::ModulesOpenvpnRandomizeHostname, c.randomizeHostnames);
    }
    Finish();
}
