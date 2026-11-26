// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/managers/VersionChecker.h"
#include "Worker.h"
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
                      Models::AppConstants_github github
    );
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
    // Destroy first: cancels and joins before captured state and dependencies.
    Worker worker_;
};
}
