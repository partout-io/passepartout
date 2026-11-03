// SPDX-License-Identifier: GPL-3.0
#pragma once
#include "profiles.h"
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
    explicit TunnelManager(std::unique_ptr<TunnelStrategy> strategy);
    std::vector<Models::AppTunnelInfo> Fetch();
    void Connect(const Profile &profile);
    void Disconnect(const std::string &id);
    void Remove(const std::string &id);
private:
    std::unique_ptr<TunnelStrategy> strategy_;
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
