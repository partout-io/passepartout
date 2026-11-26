// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "EventEmitter.h"
#include <utility>

namespace Passepartout {
std::size_t EventEmitter::Subscribe(Handler handler) {
    const auto subscription = ++next_subscription_;
    handlers_.emplace(subscription, std::move(handler));
    return subscription;
}

void EventEmitter::Unsubscribe(std::size_t subscription) {
    handlers_.erase(subscription);
}

void EventEmitter::Emit(const Models::Event &event) {
    for (const auto &[subscription, handler] : handlers_) handler(event);
}
}
