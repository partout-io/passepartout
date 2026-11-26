// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <partout/tunnel/TunnelStrategy.h>
#include "../extensions/Models+Business.h"

namespace Passepartout {
// A deterministic development dependency; never selected silently in production.
class FakeTunnelStrategy final : public Partout::TunnelStrategy {
public:
    std::vector<Partout::Models::TunnelSnapshot> Fetch() override;
    void Save(const Profile &profile) override;
    void Connect(const std::string &id) override;
    void Disconnect(const std::string &id) override;
    void Remove(const std::string &id) override;
    void SetStatus(const std::string &id, Partout::Models::TunnelStatus::eTunnelStatus status);
private:
    std::vector<Partout::Models::TunnelSnapshot> tunnels_;
};
}
