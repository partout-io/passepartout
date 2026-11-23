// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Module.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
wxString Modules::Title(const Partout::Models::TaggedModule &module) {
    using namespace Partout::Models;
    using namespace Strings::Unlocalized;
    if (std::holds_alternative<TaggedModuleDns>(module)) return DNS;
    if (std::holds_alternative<TaggedModuleIp>(module)) return IP;
    if (std::holds_alternative<TaggedModuleHTTPProxy>(module)) return HTTPProxy;
    if (std::holds_alternative<TaggedModuleOpenVpn>(module)) return OpenVPN;
    if (std::holds_alternative<TaggedModuleWireGuard>(module)) return WireGuard;
    return Localized(StringKey::GlobalNounsOnDemand);
}
}
