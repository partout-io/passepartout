// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <condition_variable>
#include <deque>
#include <functional>
#include <mutex>
#include <thread>

namespace Passepartout {
// Owned by one observable. Stop cancels its external work before joining, and
// callers stop it before destroying any state captured by queued operations.
class BackgroundWorker final {
public:
    explicit BackgroundWorker(std::function<void()> cancel = {});
    ~BackgroundWorker();
    bool Post(std::function<void()> operation);
    void Stop();
private:
    void Run();
    std::function<void()> cancel_;
    std::mutex mutex_;
    std::condition_variable wake_;
    std::deque<std::function<void()>> operations_;
    bool stopping_ = false;
    std::thread worker_;
};
}
