// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <cstdint>
#include <functional>
#include <utility>
#include <optional>

namespace Passepartout {
// The owner protects this tracker and its state with the same mutex.
// Keep one cursor per consumer and observable instance.
template<typename State>
class SnapshotTracker final {
public:
    class Cursor final {
        friend class SnapshotTracker;
        std::optional<std::uint64_t> revision_;
    };

    // Invoked under the owner's mutex. Enqueue delivery; do not read state here.
    void SetChangeHandler(std::function<void()> handler) {
        on_change_ = std::move(handler);
    }

    void Advance() {
        ++revision_;
        if (on_change_) on_change_();
    }

    std::optional<State> SnapshotIfChanged(Cursor &cursor, const State &state) const {
        if (cursor.revision_ == revision_) return {};
        auto result = state;
        cursor.revision_ = revision_;
        return result;
    }

private:
    std::uint64_t revision_ = 0;
    std::function<void()> on_change_;
};
}
