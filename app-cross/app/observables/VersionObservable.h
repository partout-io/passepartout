// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/managers/VersionChecker.h"
#include "BackgroundWorker.h"

namespace Passepartout {
class VersionObservable final {
public:
    struct State {
        std::string current;
        std::string changelog;
        VersionChecker::State release;
        bool available = false;
        bool checking = false;
        bool operation_failed = false;
    };
    VersionObservable(std::unique_ptr<VersionChecker> checker, std::string current, std::string changelog);
    ~VersionObservable();
    State Snapshot() const;
    void Check();
private:
    std::unique_ptr<VersionChecker> checker_;
    mutable std::mutex mutex_;
    State state_;
    BackgroundWorker worker_;
};
}
