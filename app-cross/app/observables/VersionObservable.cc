// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "VersionObservable.h"
#include <chrono>

namespace Passepartout {
VersionObservable::VersionObservable(std::unique_ptr<VersionChecker> checker, std::string current, std::string changelog)
    : checker_(std::move(checker)), worker_([this] {
        checker_->Cancel();
    }) {
    state_.current = std::move(current);
    state_.changelog = std::move(changelog);
    state_.available = checker_->Available();
    state_.release = checker_->Snapshot();
}
VersionObservable::~VersionObservable() {
    worker_.Stop();
}
VersionObservable::State VersionObservable::Snapshot() const {
    std::lock_guard lock(mutex_);
    return state_;
}
void VersionObservable::Check() {
    std::lock_guard lock(mutex_);
    if (!state_.available || state_.checking) return;
    state_.checking = true;
    worker_.Post([this] {
        bool failed = false;
        try {
            const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
            checker_->Check(now);
        } catch (...) {
            failed = true;
        }
        std::lock_guard lock(mutex_);
        state_.release = checker_->Snapshot();
        state_.failed = failed;
        state_.checking = false;
    });
}
}
