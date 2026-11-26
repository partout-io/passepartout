// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <thread>

namespace Passepartout {
// Owners must request stop, cancel blocking dependencies, then join before destroying them.
class SerialExecutor final {
public:
    struct Activity final {
        bool busy = false;
        bool foreground = false;
        std::uint64_t revision = 0;
    };
    SerialExecutor();
    ~SerialExecutor();
    bool Post(std::function<void()> operation, bool foreground = true);
    // Deliver dependent work inline on the worker, preserving publication order.
    bool Dispatch(std::function<void()> operation, bool foreground = true);
    Activity Snapshot() const;
    bool IsStopping() const;
    void RequestStop();
    void Join();
    bool WaitIdle(std::chrono::milliseconds timeout);
private:
    void Run();
    struct Operation final {
        std::function<void()> run;
        bool foreground;
    };
    mutable std::mutex mutex_;
    std::condition_variable wake_;
    std::deque<Operation> operations_;
    Activity activity_;
    bool stopping_ = false;
    std::thread::id worker_id_;
    std::thread worker_;
};
}
