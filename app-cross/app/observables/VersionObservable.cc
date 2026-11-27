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
    subscription_ = checker_->events.Subscribe([this](const Models::Event &event) {
        if (!std::holds_alternative<Models::VersionEventNew>(event)) return;
        delivery_.Post([this, release = checker_->Snapshot()] {
            state_.release = release;
            changes.Emit();
        });
    });
    state_.available = checker_->Available();
    state_.release = checker_->Snapshot();
}

VersionObservable::~VersionObservable() {
    MainThread::Assert();
    worker_.Stop();
    checker_->events.Unsubscribe(subscription_);
}

VersionObservable::State VersionObservable::Snapshot() const {
    MainThread::Assert();
    return state_;
}

void VersionObservable::Check() {
    MainThread::Assert();
    if (!state_.available || state_.checking) return;
    state_.checking = true;
    state_.release = {};
    changes.Emit();
    worker_.Post([this] {
        bool operation_failed = false;
        try {
            const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
            checker_->Check(now);
        } catch (...) {
            operation_failed = true;
        }
        delivery_.Post([this, operation_failed] {
            state_.operation_failed = operation_failed;
            state_.checking = false;
            changes.Emit();
        });
    });
}

void VersionObservable::LoadChangelog(std::string build) {
    MainThread::Assert();
    if (state_.changelog.loading && state_.changelog.build == build) return;
    const auto request = ++changelog_request_;
    state_.changelog = {};
    state_.changelog.build = build;
    state_.changelog.loading = true;
    changes.Emit();
    worker_.Post([this, build = std::move(build), request] {
        ChangelogState result;
        result.build = build;
        try {
            result.entries = checker_->FetchChangelog(build);
        } catch (...) {
            AppLog::Write(AppLog::Level::error, AppLog::Category::core, "Unable to load changelog for build " + build);
            result.operation_failed = true;
        }
        delivery_.Post([this, request, result = std::move(result)]() mutable {
            if (request != changelog_request_) return;
            state_.changelog = std::move(result);
            changes.Emit();
        });
    });
}
}
