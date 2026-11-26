// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ConfigObservable.h"

namespace Passepartout {
ConfigObservable::ConfigObservable(std::unique_ptr<ConfigManager> manager)
    : manager_(std::move(manager)), worker_([this] {
        manager_->Cancel();
    }) {
    state_.flags = manager_->ActiveFlags();
}

ConfigObservable::State ConfigObservable::Snapshot() const {
    std::lock_guard lock(mutex_);
    return state_;
}

void ConfigObservable::Refresh() {
    std::lock_guard lock(mutex_);
    if (state_.refreshing) return;
    state_.refreshing = true;
    worker_.Post([this] {
        State result;
        try {
            manager_->Refresh();
        } catch (...) {
            result.operation_failed = true;
        }
        result.flags = manager_->ActiveFlags();
        std::lock_guard lock(mutex_);
        state_ = std::move(result);
    });
}
}
