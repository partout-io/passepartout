// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Event.h"
#include <cstddef>
#include <functional>
#include <map>

namespace Passepartout {
// Synchronous delivery on the owner's executor. Configure subscriptions before
// starting work and remove them after stopping it; handlers must not modify them.
class EventEmitter final {
public:
    using Handler = std::function<void(const Models::Event &)>;
    std::size_t Subscribe(Handler handler);
    void Unsubscribe(std::size_t subscription);
    void Emit(const Models::Event &event);
private:
    std::map<std::size_t, Handler> handlers_;
    std::size_t next_subscription_ = 0;
};
}
