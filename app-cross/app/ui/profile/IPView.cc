// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "IPView.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
IPView::IPView(wxWindow *parent, const Partout::Models::IPModule &module, OpenModuleContent openContent)
    : ModuleDetailView(parent, std::move(openContent), Presentation::Form) {
    using namespace Strings::Unlocalized;
    const auto &c = module;
    IP(IPv4, c.ipv4);
    IP(IPv6, c.ipv6);
    if (module.mtu) {
        Section(Localized(StringKey::GlobalNounsInterface));
        Row(MTU, *module.mtu);
    }
    Finish();
}
}
