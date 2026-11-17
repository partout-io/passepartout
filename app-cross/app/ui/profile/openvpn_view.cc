// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "openvpn_view.h"
#include "../../strings/unlocalized.h"
#include <wx/base64.h>

namespace Passepartout {
namespace {
wxString HexKey(const nlohmann::json &value) {
    if (!value.is_string()) return {};
    const auto decoded = wxBase64Decode(wxString::FromUTF8(value.get<std::string>()));
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
OpenVPNView::OpenVPNView(wxWindow *parent, const Partout::Models::OpenVPNModule &module, OpenModuleContent openContent, std::function<void()> openCredentials)
    : ModuleDetailView(parent, std::move(openContent)) {
    using namespace Strings::Unlocalized;
    if (!module.configuration) return;
    const auto c = module.configuration->ToJson();
    auto value = [&](const char *name) {
        return c.value(name, nlohmann::json());
    };
    if (HasContent(value("remotes"))) {
        Section(Localized(StringKey::GlobalNounsConnection));
        Row(StringKey::ModulesOpenvpnRemotes, value("remotes"), true);
    }
    if (module.configuration->authUserPass.value_or(false)) {
        Section(Localized(StringKey::GlobalNounsAccount));
        Navigate(Localized(StringKey::ModulesOpenvpnCredentials), std::move(openCredentials));
    }
    const auto noPull = value("noPullMask");
    std::vector<wxString> pulled;
    for (const auto &entry : std::vector<std::pair<std::string, wxString>>{
        {"routes", Localized(StringKey::GlobalNounsRoutes)}, {"dns", DNS}, {"proxy", Proxy}}) {
        if (!noPull.is_array() || std::find(noPull.begin(), noPull.end(), entry.first) == noPull.end())
            pulled.push_back(entry.second);
    }
    if (!pulled.empty()) {
        Section(Localized(StringKey::ModulesOpenvpnPull));
        std::sort(pulled.begin(), pulled.end());
        for (const auto &title : pulled) Field(title, Localized(StringKey::GlobalNounsEnabled));
    }
    const auto policies = value("routingPolicies");
    if (policies.is_array() && std::any_of(policies.begin(), policies.end(), [](const auto &policy) {
        return policy == "IPv4" || policy == "IPv6";
    })) {
        Section(Localized(StringKey::ModulesOpenvpnRedirectGateway));
        for (const auto *family : {IPv4, IPv6}) {
            if (std::find(policies.begin(), policies.end(), family) != policies.end())
                Field(family, Localized(StringKey::GlobalNounsEnabled));
        }
    }
    IP(IPv4, value("ipv4"), value("routes4"), true);
    IP(IPv6, value("ipv6"), value("routes6"), true);
    if (HasContent(value("dnsServers")) || HasContent(value("dnsDomain")) || HasContent(value("searchDomains"))) {
        Section(DNS);
        Row(StringKey::GlobalNounsServers, value("dnsServers"));
        Row(StringKey::GlobalNounsDomain, value("dnsDomain"));
        Row(StringKey::EntitiesDnsSearchDomains, value("searchDomains"));
    }
    if (HasContent(value("httpProxy")) || HasContent(value("httpsProxy")) ||
        HasContent(value("proxyAutoConfigurationURL")) || HasContent(value("proxyBypassDomains"))) {
        Section(Proxy);
        Row(HTTP, value("httpProxy"));
        Row(HTTPS, value("httpsProxy"));
        Row(PAC, value("proxyAutoConfigurationURL"));
        Row(StringKey::EntitiesHttpProxyBypassDomains, value("proxyBypassDomains"));
    }
    if (HasContent(value("dataCiphers")) || HasContent(value("cipher")) || HasContent(value("digest")) || HasContent(value("xorMethod"))) {
        Section(Localized(StringKey::ModulesOpenvpnCommunication));
        if (value("dataCiphers").is_array()) {
            std::string ciphers;
            for (const auto &cipher : value("dataCiphers")) {
                if (!ciphers.empty()) ciphers += ':';
                ciphers += cipher.get<std::string>();
            }
            Row(StringKey::ModulesOpenvpnDataCiphers, ciphers, true);
        }
        Row(StringKey::ModulesOpenvpnCipher, value("cipher"));
        Row(StringKey::ModulesOpenvpnDigest, value("digest"));
        const auto xorMethod = value("xorMethod");
        if (xorMethod.is_object()) {
            auto text = ValueText(xorMethod.at("type"));
            const auto mask = HexKey(xorMethod.value("mask", nlohmann::json()));
            if (!mask.empty()) text += " " + mask;
            Row(XOR, text.ToStdString(wxConvUTF8), true);
        }
    }
    if (HasContent(value("compressionFraming")) || HasContent(value("compressionAlgorithm"))) {
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
    if (HasContent(value("ca")) || HasContent(value("clientCertificate")) || HasContent(value("clientKey")) || HasContent(value("tlsWrap"))) {
        Section(TLS);
        Row(CA, value("ca"), true);
        Row(StringKey::GlobalNounsCertificate, value("clientCertificate"), true);
        Row(StringKey::GlobalNounsKey, value("clientKey"), true);
        const auto wrap = value("tlsWrap");
        if (wrap.is_object()) {
            const auto strategy = wrap.at("strategy");
            const auto name = strategy == "auth" ? TLSAuth : strategy == "crypt" ? TLSCrypt : TLSCryptV2;
            const auto key = HexKey(wrap.at("key").at("data"));
            if (!key.empty()) {
                const auto title = Localized(StringKey::ModulesOpenvpnTlsWrap) + " (" + name + ")";
                Navigate(title, [this, title, key] {
                    openContent_(title, key);
                });
            }
        }
        Row(StringKey::ModulesOpenvpnEku, module.configuration->checksEKU.value_or(false));
    }
    if (HasContent(value("keepAliveInterval")) || HasContent(value("keepAliveTimeout"))) {
        Section(Localized(StringKey::GlobalNounsKeepAlive));
        Duration(StringKey::GlobalNounsInterval, value("keepAliveInterval"));
        Duration(StringKey::GlobalNounsTimeout, value("keepAliveTimeout"));
    }
    if (HasContent(value("renegotiatesAfter")) || HasContent(value("randomizeEndpoint")) || HasContent(value("randomizeHostnames"))) {
        Section(Localized(StringKey::GlobalNounsOther));
        Duration(StringKey::ModulesOpenvpnRenegotiation, value("renegotiatesAfter"));
        Row(StringKey::ModulesOpenvpnRandomizeEndpoint, value("randomizeEndpoint"));
        Row(StringKey::ModulesOpenvpnRandomizeHostname, value("randomizeHostnames"));
    }
    Finish();
}
}
