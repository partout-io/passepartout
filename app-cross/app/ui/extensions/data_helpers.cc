// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "data_helpers.h"
#include <algorithm>
#include <iomanip>
#include <locale>
#include <sstream>

namespace Passepartout {
std::string FormatDataUnit(int64_t bytes, NumberFormatter formatter) {
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
