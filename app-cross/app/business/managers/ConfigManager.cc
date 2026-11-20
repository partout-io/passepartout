// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ConfigManager.h"
#include <algorithm>
#include <stdexcept>

namespace Passepartout {
ConfigManager::ConfigManager(std::unique_ptr<HttpClient> client, std::string url, int build,
                             std::chrono::seconds ttl)
    : client_(std::move(client)), url_(std::move(url)), build_(build), ttl_(ttl) {}
bool ConfigManager::Refresh() {
    const auto now = std::chrono::steady_clock::now();
    if (refreshed_ && now - *refreshed_ < ttl_) return false;
    const auto bundle = nlohmann::json::parse(client_->Get(url_));
    if (!bundle.is_object()) throw std::runtime_error("Invalid configuration bundle.");
    Flags flags;
    for (const auto &entry : bundle.items()) {
        Models::ConfigFlag::eConfigFlag flag;
        try {
            flag = Models::ConfigFlag::FromJson(entry.key()).value;
        } catch (const std::invalid_argument &) {
            continue;
        }
        if (flag == Models::ConfigFlag::unknown ||
            flag == Models::ConfigFlag::INVALID_VALUE_OPENAPI_GENERATED) continue;
        const auto config = Models::ConfigBundleConfig::FromJson(entry.value());
        if (config.rate != 100 || (config.minBuild && *config.minBuild > build_)) continue;
        if (config.platforms && std::none_of(config.platforms->begin(), config.platforms->end(), [](const auto &platform) {
            return platform.value == Models::Platform::windows;
        })) continue;
        flags.emplace(flag, config.data.value_or(nlohmann::json()));
    }
    flags_ = std::move(flags);
    refreshed_ = now;
    return true;
}
const ConfigManager::Flags &ConfigManager::ActiveFlags() const {
    return flags_;
}
void ConfigManager::Cancel() noexcept {
    client_->Cancel();
}
}
