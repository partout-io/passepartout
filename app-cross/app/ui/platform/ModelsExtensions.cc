// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../extensions/ModelsExtensions.h"
#include "../../business/extensions/ModelsExtensions.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"
#include <wx/string.h>

namespace Passepartout {
std::filesystem::path Paths::FromString(const wxString &value) {
    return FromUtf8(value.ToStdString(wxConvUTF8));
}
}

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
