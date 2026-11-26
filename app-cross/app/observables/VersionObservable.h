// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/managers/VersionChecker.h"
#include "Worker.h"

namespace Passepartout {
class VersionObservable final {
public:
    struct ChangelogState final {
        std::string build;
        std::vector<Models::ChangelogEntry> entries;
        bool loading = false;
        bool operation_failed = false;
    };

    struct State final {
        VersionChecker::State release;
        ChangelogState changelog;
        bool available = false;
        bool checking = false;
        bool operation_failed = false;
    };
    ~VersionObservable();
    explicit VersionObservable(std::unique_ptr<VersionChecker> checker);
    State Snapshot() const;
    void Check();
    void LoadChangelog(std::string build);
private:
    void OnUpdate(const Models::Event &event);
    std::size_t subscription_;
    std::unique_ptr<VersionChecker> checker_;
    mutable std::mutex mutex_;
    State state_;
    std::uint64_t changelog_request_ = 0;
    // Destroy first: cancels and joins before captured state and dependencies.
    Worker worker_;
};
}
