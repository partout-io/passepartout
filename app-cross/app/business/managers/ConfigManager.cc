// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ConfigManager.h"
#include <algorithm>

namespace Passepartout {
ConfigManager::ConfigManager(std::unique_ptr<ConfigManagerStrategy> strategy, int build, Models::Platform::ePlatform platform)
    : strategy_(std::move(strategy)), build_(build), platform_(platform) {}

std::size_t ConfigManager::Subscribe(EventHandler handler) {
    const auto subscription = ++next_subscription_;
    handlers_.emplace(subscription, std::move(handler));
    return subscription;
}

void ConfigManager::Unsubscribe(std::size_t subscription) {
    handlers_.erase(subscription);
}

void ConfigManager::Emit(const Models::Event &event) {
    for (const auto &[subscription, handler] : handlers_) handler(event);
}

bool ConfigManager::Refresh() {
    const auto bundle = strategy_->Bundle();
    if (!bundle) return false;
    ConfigFlags flags;
    for (const auto &entry : *bundle) {
        const auto &config = entry.second;
        if (config.rate != 100 || (config.minBuild && *config.minBuild > build_)) continue;
        if (config.platforms && std::none_of(config.platforms->begin(), config.platforms->end(), [this](const auto &platform) {
            return platform.value == platform_;
        })) continue;
        flags.emplace(entry.first, config.data.value_or(Partout::Json()));
    }
    flags_ = std::move(flags);
    Models::ConfigEventRefresh event;
    std::map<std::string, Partout::Json> data;
    for (const auto &[key, value] : flags_) {
        Models::ConfigFlag flag;
        flag.value = key;
        event.flags.push_back(flag);
        if (!value.IsNull()) data.emplace(flag.ToString(), value);
    }
    event.data = Partout::Json(data);
    Emit(event);
    return true;
}

const ConfigFlags &ConfigManager::ActiveFlags() const {
    return flags_;
}

void ConfigManager::Cancel() noexcept {
    strategy_->Cancel();
}
}
