// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "TunnelInfo.h"
#include <stdexcept>

using namespace Passepartout;

std::vector<Models::AppTunnelInfo> Passepartout::Tunnels::Info(const std::vector<Partout::Models::TunnelSnapshot> &snapshots) {
    std::vector<Models::AppTunnelInfo> result;
    for (const auto &snapshot : snapshots) {
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
            case Partout::Models::TunnelStatus::inactive:
                info.status.value = Status::disconnected;
                break;
            case Partout::Models::TunnelStatus::activating:
                info.status.value = Status::connecting;
                break;
            case Partout::Models::TunnelStatus::active:
                info.status.value = Status::connected;
                break;
            case Partout::Models::TunnelStatus::deactivating:
                info.status.value = Status::disconnecting;
                break;
            default:
                throw std::runtime_error("Unknown tunnel status.");
        }
        result.push_back(std::move(info));
    }
    return result;
}
