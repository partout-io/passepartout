// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/config_manager.h"
#include "../business/background_worker.h"

namespace Passepartout {
class ConfigObservable {
public:
    struct State {
        ConfigManager::Flags flags;
        bool refreshing = false;
        bool failed = false;
    };
    explicit ConfigObservable(std::unique_ptr<ConfigManager> manager);
    ~ConfigObservable();
    State Snapshot() const;
    void Refresh();
private:
    std::unique_ptr<ConfigManager> manager_;
    mutable std::mutex mutex_;
    State state_;
    BackgroundWorker worker_;
};
}
