// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "GitHubConfigStrategy.h"
#include <stdexcept>

namespace Passepartout {
GitHubConfigStrategy::GitHubConfigStrategy(std::unique_ptr<HttpClient> client, std::string url, std::chrono::seconds ttl)
    : client_(std::move(client)), url_(std::move(url)), ttl_(ttl) {}

std::optional<ConfigBundle> GitHubConfigStrategy::Bundle() {
    const auto now = std::chrono::steady_clock::now();
    if (refreshed_ && now - *refreshed_ < ttl_) return {};
    const auto json = Partout::Json::Parse(client_->Get(url_));
    if (!json.IsObject()) throw std::runtime_error("Invalid configuration bundle.");
    ConfigBundle bundle;
    for (const auto &entry : json.Members()) {
        Models::ConfigFlag::eConfigFlag flag;
        try {
            flag = Models::ConfigFlag::FromJson(entry.first).value;
        } catch (const std::invalid_argument &) {
            continue;
        }
        if (flag == Models::ConfigFlag::unknown ||
            flag == Models::ConfigFlag::INVALID_VALUE_OPENAPI_GENERATED) continue;
        bundle.emplace(flag, Models::ConfigBundleConfig::FromJson(entry.second));
    }
    refreshed_ = now;
    return bundle;
}

void GitHubConfigStrategy::Cancel() noexcept {
    client_->Cancel();
}
}
