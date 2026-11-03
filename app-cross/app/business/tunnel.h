// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "profiles.h"
#include "logging.h"
#include <chrono>
#include <optional>
#include "AppTunnelInfo.h"

namespace Passepartout {
using Status = Models::AppProfileStatus::eAppProfileStatus;
class TunnelStrategy {
public:
    virtual ~TunnelStrategy() = default;
    // All calls run on the same background worker, never the UI thread.
    virtual std::vector<Models::AppTunnelInfo> Fetch() = 0;
    virtual void Save(const Profile &profile) = 0;
    virtual void Connect(const std::string &id) = 0;
    virtual void Disconnect(const std::string &id) = 0;
    virtual void Remove(const std::string &id) = 0;
};

class TunnelManager {
public:
    explicit TunnelManager(std::unique_ptr<TunnelStrategy> strategy,
        std::shared_ptr<AppLogger> logger = std::make_shared<AppLogger>(),
        std::chrono::milliseconds handoverTimeout = std::chrono::seconds(60));
    void Advance();
    void CancelPending(const std::string &id);
    std::optional<std::string> PendingProfile() const;
    std::vector<Models::AppTunnelInfo> Fetch();
    void Connect(const Profile &profile);
    void Disconnect(const std::string &id);
    void Remove(const std::string &id);
private:
    std::unique_ptr<TunnelStrategy> strategy_;
    std::shared_ptr<AppLogger> logger_;
    std::optional<Profile> pending_;
    bool connectionRequested_ = false;
    bool sawConnecting_ = false;
    std::chrono::steady_clock::time_point handoverStarted_;
    std::chrono::milliseconds handoverTimeout_;
};

// A deterministic development dependency; never selected silently in production.
class FakeTunnelStrategy final : public TunnelStrategy {
public:
    std::vector<Models::AppTunnelInfo> Fetch() override;
    void Save(const Profile &profile) override;
    void Connect(const std::string &id) override;
    void Disconnect(const std::string &id) override;
    void Remove(const std::string &id) override;
    void SetStatus(const std::string &id, Status status);
private:
    std::vector<Models::AppTunnelInfo> tunnels_;
};
std::unique_ptr<TunnelStrategy> MakeWindowsTunnelStrategy();
}
