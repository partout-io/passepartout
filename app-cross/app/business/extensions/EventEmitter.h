// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <cstddef>
#include <functional>
#include <map>
#include <mutex>
#include <utility>

namespace Passepartout {
// Synchronous delivery on the emitting thread. Unsubscribe waits for in-flight
// delivery, so a subscriber can release its captured state after unsubscribing.
// Handlers must not subscribe, unsubscribe, or emit on this same emitter.
// Manager handlers capture data before dispatching to main-thread observables.
// View handlers enqueue presentation work to avoid reentering this emitter.
template<typename... Args>
class EventEmitter final {
public:
    using Handler = std::function<void(Args...)>;

    std::size_t Subscribe(Handler handler) {
        std::lock_guard lock(mutex_);
        const auto subscription = ++next_subscription_;
        handlers_.emplace(subscription, std::move(handler));
        return subscription;
    }

    void Unsubscribe(std::size_t subscription) {
        std::lock_guard lock(mutex_);
        handlers_.erase(subscription);
    }

    void Emit(Args... args) {
        std::lock_guard lock(mutex_);
        for (const auto &[subscription, handler] : handlers_) handler(args...);
    }
private:
    std::mutex mutex_;
    std::map<std::size_t, Handler> handlers_;
    std::size_t next_subscription_ = 0;
};
}
