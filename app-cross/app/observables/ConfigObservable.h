// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "MainThread.h"
#include "../business/managers/ConfigManager.h"
#include "Worker.h"

namespace Passepartout {
class ConfigObservable final {
public:
    struct State final {
        ConfigFlags flags;
        bool refreshing = false;
        bool operation_failed = false;
    };
    ~ConfigObservable();
    explicit ConfigObservable(std::unique_ptr<ConfigManager> manager);
    State Snapshot() const;
    void Refresh();
private:
    MainThread delivery_;
    std::size_t subscription_;
    std::unique_ptr<ConfigManager> manager_;
    State state_;
    // Destroy first: cancels and joins before captured state and dependencies.
    Worker worker_;
};
}
