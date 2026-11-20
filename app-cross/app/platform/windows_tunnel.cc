// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../business/tunnel.h"
#include "partout_winrt.h"
#include <partout/models/TunnelSnapshot.h>
#include <stdexcept>

namespace Passepartout {
namespace {
class WindowsTunnelStrategy final : public TunnelStrategy {
public:
    explicit WindowsTunnelStrategy(const std::string &serverUri) : tunnel_(serverUri) {}
    std::vector<Models::AppTunnelInfo> Fetch() override {
        std::vector<Models::AppTunnelInfo> result;
        for (const auto &snapshot : tunnel_.Fetch(&observationErrors_)) {
            Models::AppTunnelInfo info{};
            info.id = snapshot.id;
            info.isEnabled = snapshot.isEnabled;
            info.onDemand = snapshot.onDemand;
            if (snapshot.environment) {
                Models::ProfileTransfer transfer{};
                transfer.received = snapshot.environment->dataCount.received;
                transfer.sent = snapshot.environment->dataCount.sent;
                info.transfer = transfer;
                info.lastErrorCode = snapshot.environment->lastErrorCode;
            }
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
    std::map<std::string, std::string> ObservationErrors() const override {
        return observationErrors_;
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
    std::map<std::string, std::string> observationErrors_;
};
}
std::unique_ptr<TunnelStrategy> MakeWindowsTunnelStrategy(const std::string &serverUri) {
    return std::make_unique<WindowsTunnelStrategy>(serverUri);
}
}
