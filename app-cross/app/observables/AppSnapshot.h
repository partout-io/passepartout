// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/TunnelStrategy.h"
#include "AppProfileHeader.h"

namespace Passepartout {
enum class AppErrorContext { general, import, tunnel };

struct AppSnapshot {
    std::vector<Models::AppProfileHeader> profiles;
    std::vector<Models::AppTunnelInfo> tunnels;
    std::map<std::string, std::string> tunnelObservationErrors;
    bool loaded = false;
    bool busy = true;
    bool tunnelAvailable = false;
    bool foregroundBusy = false;
    std::optional<std::string> pendingProfile;
    std::vector<std::string> recoveringProfiles;
    bool HasActivity() const;
    std::string error;
    std::string tunnelError;
    std::string reconciliationError;
    AppErrorContext errorContext = AppErrorContext::general;
    std::uint64_t revision = 0;
};
}
