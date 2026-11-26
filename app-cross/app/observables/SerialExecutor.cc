// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "SerialExecutor.h"
#include <algorithm>

namespace Passepartout {
SerialExecutor::SerialExecutor() : worker_([this] {
    Run();
}) {}

SerialExecutor::~SerialExecutor() {
    RequestStop();
    Join();
}

bool SerialExecutor::Post(std::function<void()> operation, bool foreground) {
    {
        std::lock_guard lock(mutex_);
        if (stopping_) return false;
        operations_.push_back({std::move(operation), foreground});
        activity_.busy = true;
        activity_.foreground = activity_.foreground || foreground;
        ++activity_.revision;
    }
    wake_.notify_all();
    return true;
}

bool SerialExecutor::Dispatch(std::function<void()> operation, bool foreground) {
    bool is_worker;
    {
        std::lock_guard lock(mutex_);
        if (stopping_) return false;
        is_worker = std::this_thread::get_id() == worker_id_;
    }
    if (!is_worker) return Post(std::move(operation), foreground);
    operation();
    return true;
}

SerialExecutor::Activity SerialExecutor::Snapshot() const {
    std::lock_guard lock(mutex_);
    return activity_;
}

bool SerialExecutor::IsStopping() const {
    std::lock_guard lock(mutex_);
    return stopping_;
}

void SerialExecutor::RequestStop() {
    {
        std::lock_guard lock(mutex_);
        stopping_ = true;
        operations_.clear();
    }
    wake_.notify_all();
}

void SerialExecutor::Join() {
    if (worker_.joinable()) worker_.join();
}

bool SerialExecutor::WaitIdle(std::chrono::milliseconds timeout) {
    std::unique_lock lock(mutex_);
    return wake_.wait_for(lock, timeout, [&] {
        return !activity_.busy;
    });
}

void SerialExecutor::Run() {
    {
        std::lock_guard lock(mutex_);
        worker_id_ = std::this_thread::get_id();
    }
    for (;;) {
        Operation operation;
        {
            std::unique_lock lock(mutex_);
            wake_.wait(lock, [&] {
                return stopping_ || !operations_.empty();
            });
            if (stopping_) {
                activity_.busy = false;
                activity_.foreground = false;
                ++activity_.revision;
                wake_.notify_all();
                return;
            }
            operation = std::move(operations_.front());
            operations_.pop_front();
        }
        operation.run();
        {
            std::lock_guard lock(mutex_);
            activity_.busy = !operations_.empty();
            activity_.foreground = std::any_of(operations_.begin(), operations_.end(), [](const auto &queued) {
                return queued.foreground;
            });
            ++activity_.revision;
        }
        wake_.notify_all();
    }
}
}
