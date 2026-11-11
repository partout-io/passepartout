// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "data_helpers.h"
#include <algorithm>
#include <iomanip>
#include <locale>
#include <sstream>

namespace Passepartout {
std::string FormatDataUnit(int64_t bytes) {
    // Same units, thresholds, and decimal locale as Android DataHelpers+UI.
    constexpr int64_t kilobyte = 1024;
    constexpr int64_t megabyte = kilobyte * 1024;
    constexpr int64_t gigabyte = megabyte * 1024;
    bytes = std::max<int64_t>(0, bytes);
    if (bytes < kilobyte) return std::to_string(bytes) + "B";
    if (bytes < megabyte / 10) return std::to_string(bytes / kilobyte) + "kB";
    const auto unit = bytes >= gigabyte / 10 ? gigabyte : megabyte;
    std::ostringstream text;
    text.imbue(std::locale::classic());
    text << std::fixed << std::setprecision(2) << static_cast<double>(bytes) / unit;
    return text.str() + (unit == gigabyte ? "GB" : "MB");
}
}
