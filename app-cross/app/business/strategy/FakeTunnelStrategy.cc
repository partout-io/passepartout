// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "FakeTunnelStrategy.h"
#include <algorithm>
#include <stdexcept>

namespace Passepartout {
std::vector<Models::AppTunnelInfo> FakeTunnelStrategy::Fetch() {
    return tunnels_;
}
void FakeTunnelStrategy::Save(const Profile &profile) {
    for (const auto &tunnel : tunnels_) {
        if (tunnel.id == profile.id) return;
    }
    Models::AppTunnelInfo info{};
    info.id = profile.id;
    info.status.value = Status::disconnected;
    tunnels_.push_back(info);
}
void FakeTunnelStrategy::SetStatus(const std::string &id, Status status) {
    for (auto &tunnel : tunnels_) {
        if (tunnel.id != id) continue;
        tunnel.status.value = status;
        tunnel.isEnabled = status != Status::disconnected;
        return;
    }
    throw std::runtime_error("The VPN profile no longer exists.");
}
void FakeTunnelStrategy::Connect(const std::string &id) {
    SetStatus(id, Status::connected);
}
void FakeTunnelStrategy::Disconnect(const std::string &id) {
    for (const auto &tunnel : tunnels_) {
        if (tunnel.id == id) {
            SetStatus(id, Status::disconnected);
            return;
        }
    }
}
void FakeTunnelStrategy::Remove(const std::string &id) {
    tunnels_.erase(std::remove_if(tunnels_.begin(), tunnels_.end(), [&](const auto &t) {
        return t.id == id;
    }), tunnels_.end());
}
}
