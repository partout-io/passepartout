// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Models+UI.h"
#include "../../business/extensions/Models+Business.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"
#include <wx/string.h>
#include <algorithm>
#include <iomanip>
#include <sstream>

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

namespace Passepartout {
std::string DataUnits::Format(int64_t bytes, DataUnits::NumberFormatter formatter) {
    // Same units and thresholds as the other frontends; native presentation
    // supplies its locale-aware formatter without coupling this helper to wx.
    if (!formatter) formatter = [](double value, int precision) {
        std::ostringstream text;
        text << std::fixed << std::setprecision(precision) << value;
        return text.str();
    };
    constexpr int64_t kilobyte = 1024;
    constexpr int64_t megabyte = kilobyte * 1024;
    constexpr int64_t gigabyte = megabyte * 1024;
    bytes = std::max<int64_t>(0, bytes);
    if (bytes < kilobyte) return formatter(static_cast<double>(bytes), 0) + "B";
    if (bytes < megabyte / 10) return formatter(static_cast<double>(bytes / kilobyte), 0) + "kB";
    const auto unit = bytes >= gigabyte / 10 ? gigabyte : megabyte;
    return formatter(static_cast<double>(bytes) / unit, 2) + (unit == gigabyte ? "GB" : "MB");
}
}

namespace Passepartout {
std::string Profiles::TransferText(const Models::ProfileTransfer &transfer, DataUnits::NumberFormatter formatter) {
    return "\xe2\x86\x93" + DataUnits::Format(transfer.received, formatter) +
           " \xe2\x86\x91" + DataUnits::Format(transfer.sent, formatter);
}
}
