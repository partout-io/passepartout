// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "tunnel.h"
#include <algorithm>
#include <stdexcept>

namespace Passepartout {
TunnelManager::TunnelManager(std::unique_ptr<TunnelStrategy> strategy, std::shared_ptr<AppLogger> logger,
                             std::chrono::milliseconds handoverTimeout)
    : strategy_(std::move(strategy)), logger_(std::move(logger)), handoverTimeout_(handoverTimeout) {}
std::vector<Models::AppTunnelInfo> TunnelManager::Fetch() {
    return strategy_->Fetch();
}
std::map<std::string, std::string> TunnelManager::ObservationErrors() const {
    return strategy_->ObservationErrors();
}
void TunnelManager::Connect(const Profile &profile) {
    logger_->Write(LogLevel::info, "tunnel", "Connect to profile " + profile.id + "...");
    pending_.reset();
    connectionRequested_ = false;
    sawConnecting_ = false;
    const auto tunnels = Fetch();
    const auto errors = ObservationErrors();
    if (const auto failure = errors.find(profile.id); failure != errors.end())
        throw std::runtime_error(failure->second);
    for (const auto &tunnel : tunnels) {
        if (tunnel.id == profile.id && tunnel.status.value == Status::connected) return;
    }
    for (const auto &tunnel : tunnels) {
        if (tunnel.status.value == Status::disconnected || tunnel.status.value == Status::disconnecting) continue;
        logger_->Write(LogLevel::info, "tunnel", "Disconnect profile " + tunnel.id + " before handover");
        strategy_->Disconnect(tunnel.id);
    }
    pending_ = profile;
    handoverStarted_ = std::chrono::steady_clock::now();
    Advance();
}
void TunnelManager::Advance() {
    if (!pending_) return;
    try {
        const auto tunnels = Fetch();
        const auto errors = ObservationErrors();
        if (const auto failure = errors.find(pending_->id); failure != errors.end())
            throw std::runtime_error(failure->second);
        if (connectionRequested_) {
            const auto target = std::find_if(tunnels.begin(), tunnels.end(), [&](const auto &tunnel) {
                return tunnel.id == pending_->id;
            });
            if (target != tunnels.end() && target->status.value == Status::connected) {
                logger_->Write(LogLevel::info, "tunnel", "Connected to profile " + pending_->id);
                pending_.reset();
                return;
            }
            if (target != tunnels.end() && target->status.value == Status::connecting) sawConnecting_ = true;
            if (sawConnecting_ && (target == tunnels.end() || target->status.value == Status::disconnected))
                throw std::runtime_error("The VPN disconnected before activation completed.");
            if (std::chrono::steady_clock::now() - handoverStarted_ >= handoverTimeout_)
                throw std::runtime_error("Timed out waiting for the requested VPN to connect.");
            return;
        }
        const bool active = std::any_of(tunnels.begin(), tunnels.end(), [](const auto &tunnel) {
            return tunnel.status.value != Status::disconnected;
        });
        if (active) {
            if (std::chrono::steady_clock::now() - handoverStarted_ >= handoverTimeout_)
                throw std::runtime_error("Timed out waiting for the active VPN to disconnect.");
            return;
        }
        // Wait for observed connections; unavailable registrations are neither
        // treated as disconnected nor selected for automatic disconnection.
        logger_->Write(LogLevel::info, "tunnel", "Install profile " + pending_->id + "...");
        strategy_->Save(*pending_);
        strategy_->Connect(pending_->id);
        logger_->Write(LogLevel::info, "tunnel", "Connect request accepted for profile " + pending_->id);
        connectionRequested_ = true;
        handoverStarted_ = std::chrono::steady_clock::now();
        Advance();
    } catch (...) {
        pending_.reset();
        throw;
    }
}
std::optional<std::string> TunnelManager::PendingProfile() const {
    if (!pending_) return std::nullopt;
    return pending_->id;
}
void TunnelManager::CancelPending(const std::string &id) {
    if (pending_ && pending_->id == id) pending_.reset();
}
void TunnelManager::Disconnect(const std::string &id) {
    pending_.reset();
    logger_->Write(LogLevel::info, "tunnel", "Disconnect profile " + id);
    strategy_->Disconnect(id);
}
void TunnelManager::Remove(const std::string &id) {
    if (pending_ && pending_->id == id) pending_.reset();
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
