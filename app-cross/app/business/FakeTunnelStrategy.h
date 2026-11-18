// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "TunnelStrategy.h"

namespace Passepartout {
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
}
