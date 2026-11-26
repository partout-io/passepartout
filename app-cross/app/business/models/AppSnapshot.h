// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../extensions/Models+Business.h"
#include "AppProfileHeader.h"

namespace Passepartout {
enum class AppErrorContext { general, import, tunnel };

struct AppSnapshot {
    std::vector<Models::AppProfileHeader> profiles;
    std::vector<Models::AppTunnelInfo> tunnels;
    std::map<std::string, std::string> tunnel_observation_errors;
    bool loaded = false;
    bool busy = true;
    bool tunnel_available = false;
    bool foreground_busy = false;
    std::optional<std::string> pending_profile;
    std::vector<std::string> recovering_profiles;
    bool HasActivity() const;
    std::string error;
    std::string tunnel_error;
    std::string reconciliation_error;
    AppErrorContext error_context = AppErrorContext::general;
    std::uint64_t revision = 0;
};
}
