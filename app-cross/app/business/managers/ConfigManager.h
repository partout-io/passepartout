// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/HttpClient.h"
#include "ConfigBundleConfig.h"
#include "ConfigFlag.h"
#include <chrono>
#include <map>

namespace Passepartout {
class ConfigManager {
public:
    using Flags = std::map<Models::ConfigFlag::eConfigFlag, nlohmann::json>;
    ConfigManager(std::unique_ptr<HttpClient> client, std::string url, int build,
                  std::chrono::seconds ttl);
    bool Refresh();
    const Flags &ActiveFlags() const;
    void Cancel() noexcept;
private:
    std::unique_ptr<HttpClient> client_;
    std::string url_;
    int build_;
    std::chrono::seconds ttl_;
    std::optional<std::chrono::steady_clock::time_point> refreshed_;
    Flags flags_;
};
}
