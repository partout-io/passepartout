// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "VersionObservable.h"
#include "../business/extensions/AppConstantsExtensions.h"
#include "../context/AppLog.h"
#include <chrono>

namespace Passepartout {
VersionObservable::VersionObservable(std::unique_ptr<VersionChecker> checker, std::string current, std::string build,
                                     Models::AppConstants_github github
)
    : checker_(std::move(checker)), build_(std::move(build)), github_(std::move(github)), worker_([this] {
        checker_->Cancel();
    }) {
    state_.current = std::move(current);
    state_.available = checker_->Available();
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
        state_.release = checker_->Snapshot();
        state_.operation_failed = operation_failed;
        state_.checking = false;
    });
}

void VersionObservable::LoadChangelog() {
    std::lock_guard lock(mutex_);
    if (state_.changelog.loading) return;
    state_.changelog = {};
    state_.changelog.loading = true;
    worker_.Post([this] {
        ChangelogState result;
        try {
            result.entries = checker_->FetchChangelog(build_);
        } catch (...) {
            AppLog::Write(AppLog::Level::error, AppLog::Category::core, "Unable to load changelog for build " + build_);
            result.operation_failed = true;
        }
        std::lock_guard lock(mutex_);
        state_.changelog = std::move(result);
    });
}

std::optional<std::string> VersionObservable::IssueURL(const Models::ChangelogEntry &entry) const {
    if (!entry.issue) return {};
    return Constants::IssueURL(github_, *entry.issue);
}
}
