// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/VersionCheckerStrategy.h"
#include "../extensions/EventEmitter.h"
#include "Event.h"
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <cstdint>

namespace Passepartout {
class VersionChecker final {
public:
    EventEmitter<const Models::Event &> events;
    struct State final {
        std::optional<std::string> latest;
        std::string download_url;
    };
    using SaveVersion = std::function<void(std::int64_t, std::optional<std::string>)>;
    VersionChecker(std::string current, std::unique_ptr<VersionCheckerStrategy> strategy,
                   std::string destination, std::int64_t rate_limit_seconds,
                   std::optional<std::int64_t> last_checked, std::optional<std::string> cached,
                   SaveVersion save);
    bool Available() const;
    State Snapshot() const;
    // Epoch milliseconds, matching AppPreferences on the other frontends.
    void Check(std::int64_t now);
    std::vector<Models::ChangelogEntry> FetchChangelog(const std::string &build);
    void Cancel() noexcept;
private:
    void PublishRelease();
    std::string current_;
    std::unique_ptr<VersionCheckerStrategy> strategy_;
    std::string destination_;
    std::int64_t rate_limit_seconds_;
    std::optional<std::int64_t> last_checked_;
    std::optional<std::string> cached_;
    SaveVersion save_;
};
}
