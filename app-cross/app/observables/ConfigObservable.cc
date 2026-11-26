// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ConfigObservable.h"

namespace Passepartout {
ConfigObservable::ConfigObservable(std::unique_ptr<ConfigManager> manager)
    : manager_(std::move(manager)), worker_([this] {
        manager_->Cancel();
    }) {
    subscription_ = manager_->events.Subscribe([this](const Models::Event &event) { OnUpdate(event); });
    state_.flags = manager_->ActiveFlags();
}

ConfigObservable::~ConfigObservable() {
    worker_.Stop();
    manager_->events.Unsubscribe(subscription_);
}

void ConfigObservable::OnUpdate(const Models::Event &event) {
    if (!std::holds_alternative<Models::ConfigEventRefresh>(event)) return;
    std::lock_guard lock(mutex_);
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
        bool operation_failed = false;
        try {
            manager_->Refresh();
        } catch (...) {
            operation_failed = true;
        }
        std::lock_guard lock(mutex_);
        state_.operation_failed = operation_failed;
        state_.refreshing = false;
    });
}
}
