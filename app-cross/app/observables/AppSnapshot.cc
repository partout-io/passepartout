// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AppSnapshot.h"
#include <algorithm>

namespace Passepartout {
bool AppSnapshot::HasActivity() const {
    if (foregroundBusy || pendingProfile) return true;
    return tunnelAvailable && std::any_of(tunnels.begin(), tunnels.end(), [](const auto &tunnel) {
        return tunnel.status.value == Status::connecting || tunnel.status.value == Status::disconnecting;
    });
}
}
