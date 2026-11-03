// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../business/tunnel.h"
#include "../context/constants.h"
#include "partout_winrt.h"
#include <partout/models/TunnelSnapshot.h>
#include <stdexcept>

namespace Passepartout {
namespace {
class WindowsTunnelStrategy final : public TunnelStrategy {
public:
    WindowsTunnelStrategy() : tunnel_(defaultCrossConstants.tunnel.profilePrefix) {}
    std::vector<Models::AppTunnelInfo> Fetch() override {
        std::vector<Models::AppTunnelInfo> result;
        for (const auto &snapshot : tunnel_.Fetch()) {
            Models::AppTunnelInfo info{};
            info.id = snapshot.id;
            info.isEnabled = snapshot.isEnabled;
            info.onDemand = snapshot.onDemand;
            switch (snapshot.status.value) {
                case Partout::Models::TunnelStatus::inactive: info.status.value = Status::disconnected; break;
                case Partout::Models::TunnelStatus::activating: info.status.value = Status::connecting; break;
                case Partout::Models::TunnelStatus::active: info.status.value = Status::connected; break;
                case Partout::Models::TunnelStatus::deactivating: info.status.value = Status::disconnecting; break;
                default: throw std::runtime_error("Unknown tunnel status.");
            }
            result.push_back(std::move(info));
        }
        return result;
    }
    void Save(const Profile &profile) override {
        ValidateProfileIdentity(profile);
        tunnel_.Save(profile);
    }
    void Connect(const std::string &id) override {
        tunnel_.Connect(id);
    }
    void Disconnect(const std::string &id) override {
        tunnel_.Disconnect(id);
    }
    void Remove(const std::string &id) override {
        tunnel_.Remove(id);
    }
private:
    Partout::Tunnel tunnel_;
};
}
std::unique_ptr<TunnelStrategy> MakeWindowsTunnelStrategy() {
    return std::make_unique<WindowsTunnelStrategy>();
}
}
