// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ConfigObservable.h"

namespace Passepartout {
ConfigObservable::ConfigObservable(std::unique_ptr<ConfigManager> manager)
    : manager_(std::move(manager)), worker_([this] {
        manager_->Cancel();
    }) {
    subscription_ = manager_->events.Subscribe([this](const Models::Event &event) {
        if (!std::holds_alternative<Models::ConfigEventRefresh>(event)) return;
        delivery_.Post([this, flags = manager_->ActiveFlags()] {
            state_.flags = flags;
        });
    });
    state_.flags = manager_->ActiveFlags();
}

ConfigObservable::~ConfigObservable() {
    MainThread::Assert();
    worker_.Stop();
    manager_->events.Unsubscribe(subscription_);
}

ConfigObservable::State ConfigObservable::Snapshot() const {
    MainThread::Assert();
    return state_;
}

void ConfigObservable::Refresh() {
    MainThread::Assert();
    if (state_.refreshing) return;
    state_.refreshing = true;
    worker_.Post([this] {
        bool operation_failed = false;
        try {
            manager_->Refresh();
        } catch (...) {
            operation_failed = true;
        }
        delivery_.Post([this, operation_failed] {
            state_.operation_failed = operation_failed;
            state_.refreshing = false;
        });
    });
}
}
