// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ConfigObservable.h"

namespace Passepartout {
ConfigObservable::ConfigObservable(std::unique_ptr<ConfigManager> manager)
    : manager_(std::move(manager)), worker_([this] {
        manager_->Cancel();
    }) {}
ConfigObservable::~ConfigObservable() {
    worker_.Stop();
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
        bool failed = false;
        try {
            manager_->Refresh();
        } catch (...) {
            failed = true;
        }
        std::lock_guard lock(mutex_);
        state_.flags = manager_->ActiveFlags();
        state_.failed = failed;
        state_.refreshing = false;
    });
}
}
