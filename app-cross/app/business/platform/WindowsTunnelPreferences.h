// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppPreferences.h"
#include <string>
#include <vector>

namespace Passepartout::Windows::Tunnel {
void ApplyPreferences(
    const Models::AppPreferences &preferences, const std::vector<std::string> &dns_fallback_servers
);
}
