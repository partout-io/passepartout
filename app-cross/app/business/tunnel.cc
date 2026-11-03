// SPDX-License-Identifier: GPL-3.0
#include "tunnel.h"
#include <algorithm>
#include <stdexcept>

namespace Passepartout {
TunnelManager::TunnelManager(std::unique_ptr<TunnelStrategy> strategy)
    : strategy_(std::move(strategy)) {}
std::vector<Models::AppTunnelInfo> TunnelManager::Fetch() {
    return strategy_->Fetch();
}
void TunnelManager::Connect(const Profile &profile) {
    for (const auto &tunnel : Fetch()) {
        if (tunnel.status.value == Status::disconnected) continue;
        if (tunnel.id == profile.id && tunnel.status.value == Status::connected) return;
        throw std::runtime_error("Disconnect the active VPN before connecting another profile.");
    }
    // Local profiles are authoritative. Recreate missing Windows profiles and
    // replace stale configuration only while disconnected.
    strategy_->Save(profile);
    strategy_->Connect(profile.id);
}
void TunnelManager::Disconnect(const std::string &id) {
    strategy_->Disconnect(id);
}
void TunnelManager::Remove(const std::string &id) {
    for (const auto &tunnel : Fetch()) {
        if (tunnel.id != id || tunnel.status.value == Status::disconnected) continue;
        strategy_->Disconnect(id);
        // An accepted disconnect is not necessarily a completed disconnect.
        for (const auto &current : Fetch()) {
            if (current.id == id && current.status.value != Status::disconnected)
                throw std::runtime_error("The VPN is still disconnecting. Retry removal when disconnected.");
        }
    }
    strategy_->Remove(id);
}

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
