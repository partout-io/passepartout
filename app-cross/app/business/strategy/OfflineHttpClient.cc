// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "OfflineHttpClient.h"
#include <stdexcept>

namespace Passepartout {
std::string OfflineHttpClient::Get(const std::string &) {
    throw std::runtime_error("Remote services are unavailable in this mode.");
}

void OfflineHttpClient::Cancel() noexcept {}
}
