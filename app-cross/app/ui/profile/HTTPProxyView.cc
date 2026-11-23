// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "HTTPProxyView.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
HTTPProxyView::HTTPProxyView(wxWindow *parent, const Partout::Models::HTTPProxyModule &module, OpenModuleContent open_content)
    : ModuleDetailView(parent, std::move(open_content), Presentation::Form) {
    using namespace Strings::Unlocalized;
    const auto &c = module;
    auto endpoint = [this](const wxString &title, const std::optional<std::string> &value) {
        if (!HasContent(value)) return;
        Section(title);
        const auto text = *value;
        const auto separator = text.rfind(':');
        long port = 0;
        if (separator != std::string::npos && separator > 0 &&
            wxString::FromUTF8(text.substr(separator + 1)).ToLong(&port)) {
            Row(StringKey::GlobalNounsAddress, text.substr(0, separator));
            Row(StringKey::GlobalNounsPort, port);
        } else Row(StringKey::GlobalNounsAddress, text);
    };
    endpoint(HTTP, c.proxy);
    endpoint(HTTPS, c.secureProxy);
    if (HasContent(c.pacURL)) {
        Section(PAC);
        Row(URL, c.pacURL);
    }
    Row(StringKey::EntitiesHttpProxyBypassDomains, c.bypassDomains);
    Finish();
}
}
