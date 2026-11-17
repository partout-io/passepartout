// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "http_proxy_view.h"
#include "../../strings/unlocalized.h"

namespace Passepartout {
HTTPProxyView::HTTPProxyView(wxWindow *parent, const Partout::Models::HTTPProxyModule &module, OpenModuleContent openContent)
    : ModuleDetailView(parent, std::move(openContent)) {
    using namespace Strings::Unlocalized;
    const auto c = module.ToJson();
    auto endpoint = [this](const wxString &title, const nlohmann::json &value) {
        if (!HasContent(value)) return;
        Section(title);
        const auto text = value.get<std::string>();
        const auto separator = text.rfind(':');
        long port = 0;
        if (separator != std::string::npos && separator > 0 &&
            wxString::FromUTF8(text.substr(separator + 1)).ToLong(&port)) {
            Row(StringKey::GlobalNounsAddress, text.substr(0, separator));
            Row(StringKey::GlobalNounsPort, port);
        } else Row(StringKey::GlobalNounsAddress, text);
    };
    endpoint(HTTP, c.value("proxy", nlohmann::json()));
    endpoint(HTTPS, c.value("secureProxy", nlohmann::json()));
    if (HasContent(c.value("pacURL", nlohmann::json()))) {
        Section(PAC);
        Row(URL, c.at("pacURL"));
    }
    Row(StringKey::EntitiesHttpProxyBypassDomains, c.value("bypassDomains", nlohmann::json()));
    Finish();
}
}
