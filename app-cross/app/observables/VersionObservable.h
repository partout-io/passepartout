// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/managers/VersionChecker.h"
#include "BackgroundWorker.h"
#include "../context/AppLogger.h"
#include "AppConstants_github.h"

namespace Passepartout {
class VersionObservable final {
public:
    struct ChangelogState final {
        std::vector<Models::ChangelogEntry> entries;
        bool loading = false;
        bool operation_failed = false;
    };

    struct State final {
        std::string current;
        ChangelogState changelog;
        VersionChecker::State release;
        bool available = false;
        bool checking = false;
        bool operation_failed = false;
    };
    VersionObservable(std::unique_ptr<VersionChecker> checker, std::string current, std::string build,
                      Models::AppConstants_github github, std::shared_ptr<AppLogger> logger
    );
    ~VersionObservable();
    State Snapshot() const;
    void Check();
    void LoadChangelog();
    std::optional<std::string> IssueURL(const Models::ChangelogEntry &entry) const;
private:
    std::unique_ptr<VersionChecker> checker_;
    mutable std::mutex mutex_;
    State state_;
    const std::string build_;
    const Models::AppConstants_github github_;
    const std::shared_ptr<AppLogger> logger_;
    BackgroundWorker worker_;
};
}
