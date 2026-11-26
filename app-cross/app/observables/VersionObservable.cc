// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "VersionObservable.h"
#include "../context/AppLog.h"
#include <chrono>

namespace Passepartout {
VersionObservable::VersionObservable(std::unique_ptr<VersionChecker> checker)
    : checker_(std::move(checker)), worker_([this] {
        checker_->Cancel();
    }) {
    subscription_ = checker_->Subscribe([this](const Models::Event &event) { OnUpdate(event); });
    state_.available = checker_->Available();
    state_.release = checker_->Snapshot();
}

VersionObservable::~VersionObservable() {
    worker_.Stop();
    checker_->Unsubscribe(subscription_);
}

void VersionObservable::OnUpdate(const Models::Event &event) {
    if (!std::holds_alternative<Models::VersionEventNew>(event)) return;
    std::lock_guard lock(mutex_);
    state_.release = checker_->Snapshot();
}

VersionObservable::State VersionObservable::Snapshot() const {
    std::lock_guard lock(mutex_);
    return state_;
}

void VersionObservable::Check() {
    std::lock_guard lock(mutex_);
    if (!state_.available || state_.checking) return;
    state_.checking = true;
    state_.release = {};
    worker_.Post([this] {
        bool operation_failed = false;
        try {
            const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
            checker_->Check(now);
        } catch (...) {
            operation_failed = true;
        }
        std::lock_guard lock(mutex_);
        state_.operation_failed = operation_failed;
        state_.checking = false;
    });
}

void VersionObservable::LoadChangelog(std::string build) {
    std::lock_guard lock(mutex_);
    if (state_.changelog.loading && state_.changelog.build == build) return;
    const auto request = ++changelog_request_;
    state_.changelog = {};
    state_.changelog.build = build;
    state_.changelog.loading = true;
    worker_.Post([this, build = std::move(build), request] {
        ChangelogState result;
        result.build = build;
        try {
            result.entries = checker_->FetchChangelog(build);
        } catch (...) {
            AppLog::Write(AppLog::Level::error, AppLog::Category::core, "Unable to load changelog for build " + build);
            result.operation_failed = true;
        }
        std::lock_guard lock(mutex_);
        if (request == changelog_request_) state_.changelog = std::move(result);
    });
}
}
