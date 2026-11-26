// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ConfigManager.h"
#include <algorithm>

namespace Passepartout {
ConfigManager::ConfigManager(std::unique_ptr<ConfigManagerStrategy> strategy, int build)
    : strategy_(std::move(strategy)), build_(build) {}

bool ConfigManager::Refresh() {
    const auto bundle = strategy_->Bundle();
    if (!bundle) return false;
    Flags flags;
    for (const auto &entry : *bundle) {
        const auto &config = entry.second;
        if (config.rate != 100 || (config.minBuild && *config.minBuild > build_)) continue;
        if (config.platforms && std::none_of(config.platforms->begin(), config.platforms->end(), [](const auto &platform) {
            return platform.value == Models::Platform::windows;
        })) continue;
        flags.emplace(entry.first, config.data.value_or(Partout::Json()));
    }
    flags_ = std::move(flags);
    return true;
}

const ConfigManager::Flags &ConfigManager::ActiveFlags() const {
    return flags_;
}

void ConfigManager::Cancel() noexcept {
    strategy_->Cancel();
}
}
