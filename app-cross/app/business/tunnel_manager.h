// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "tunnel_strategy.h"
#include "logging.h"
#include <chrono>
#include <optional>

namespace Passepartout {
class TunnelManager {
public:
    explicit TunnelManager(std::unique_ptr<TunnelStrategy> strategy,
        std::shared_ptr<AppLogger> logger = std::make_shared<AppLogger>(),
        std::chrono::milliseconds handoverTimeout = std::chrono::seconds(60));
    void Advance();
    void CancelPending(const std::string &id);
    std::optional<std::string> PendingProfile() const;
    std::vector<Models::AppTunnelInfo> Fetch();
    std::map<std::string, std::string> ObservationErrors() const;
    void Save(const Profile &profile);
    void Register(const Profile &profile);
    void ValidateNew(const Profile &profile);
    void ValidateUpdate(const Profile &profile);
    void RollbackRegistration(const std::string &id);
    void Connect(const Profile &profile);
    void Disconnect(const std::string &id);
    void Remove(const std::string &id);
    void ApplyPreferences(const Models::AppPreferences &preferences);
    void Cancel() noexcept;
private:
    std::unique_ptr<TunnelStrategy> strategy_;
    std::shared_ptr<AppLogger> logger_;
    std::optional<Profile> pending_;
    bool connectionRequested_ = false;
    bool sawConnecting_ = false;
    std::chrono::steady_clock::time_point handoverStarted_;
    std::chrono::milliseconds handoverTimeout_;
};
}
