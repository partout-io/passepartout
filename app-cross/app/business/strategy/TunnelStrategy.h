// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../models/Profile.h"
#include "AppTunnelInfo.h"
#include "AppPreferences.h"
#include <map>
#include <memory>
#include <stdexcept>

namespace Passepartout {
using Status = Models::AppProfileStatus::eAppProfileStatus;
class TunnelStrategy {
public:
    virtual ~TunnelStrategy() = default;
    // All calls run on the same background worker, never the UI thread.
    virtual std::vector<Models::AppTunnelInfo> Fetch() = 0;
    virtual std::map<std::string, std::string> ObservationErrors() const {
        return {};
    }
    virtual void Save(const Profile &profile) = 0;
    virtual void Connect(const std::string &id) = 0;
    virtual void ConnectWithCredentials(const std::string &, const Partout::Models::OpenVpnCredentials &) {
        throw std::runtime_error("Interactive login is unavailable for this tunnel strategy.");
    }
    virtual void Disconnect(const std::string &id) = 0;
    virtual void Remove(const std::string &id) = 0;
    virtual void ApplyPreferences(const Models::AppPreferences &) {}
    // Called from the shutdown thread before joining the serialized worker.
    virtual void Cancel() noexcept {}
};
}
