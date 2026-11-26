// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ConfigManagerStrategy.h"
#include "HttpClient.h"
#include <chrono>

namespace Passepartout {
class GitHubConfigStrategy final : public ConfigManagerStrategy {
public:
    GitHubConfigStrategy(std::unique_ptr<HttpClient> client, std::string url, std::chrono::seconds ttl);
    std::optional<ConfigBundle> Bundle() override;
    void Cancel() noexcept override;
private:
    std::unique_ptr<HttpClient> client_;
    std::string url_;
    std::chrono::seconds ttl_;
    std::optional<std::chrono::steady_clock::time_point> refreshed_;
};
}
