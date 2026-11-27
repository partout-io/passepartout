// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <functional>
#include <memory>

namespace Passepartout {
// One delivery lifetime per observable. Off-thread work uses the installed UI
// dispatcher; queued callbacks are discarded when this owner is destroyed.
class MainThread final {
public:
    MainThread();
    ~MainThread();
    MainThread(const MainThread &) = delete;
    MainThread &operator=(const MainThread &) = delete;
    static void Assert();
    // Install before starting workers; replace/clear only after they have joined.
    // The dispatcher must enqueue callbacks on the main thread in FIFO order.
    static void SetDispatcher(std::function<void(std::function<void()>)> dispatch);
    void Post(std::function<void()> action) const;
private:
    struct Lifetime final {};
    std::shared_ptr<Lifetime> lifetime_;
};
}
