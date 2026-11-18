// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "IPView.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
IPView::IPView(wxWindow *parent, const Partout::Models::IPModule &module, OpenModuleContent openContent)
    : ModuleDetailView(parent, std::move(openContent)) {
    using namespace Strings::Unlocalized;
    const auto c = module.ToJson();
    IP(IPv4, c.value("ipv4", nlohmann::json()));
    IP(IPv6, c.value("ipv6", nlohmann::json()));
    if (module.mtu) {
        Section(Localized(StringKey::GlobalNounsInterface));
        Row(MTU, *module.mtu);
    }
    Finish();
}
}
