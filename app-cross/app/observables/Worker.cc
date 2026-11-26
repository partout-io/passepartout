// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Worker.h"
#include <algorithm>

namespace Passepartout {
Worker::Worker(std::function<void()> cancel) : cancel_(std::move(cancel)), worker_([this] {
    Run();
}) {}

Worker::~Worker() {
    Stop();
}

bool Worker::Post(std::function<void()> operation, bool foreground) {
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

bool Worker::Dispatch(std::function<void()> operation, bool foreground) {
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

Worker::Activity Worker::CurrentActivity() const {
    std::lock_guard lock(mutex_);
    return activity_;
}

bool Worker::IsStopping() const {
    std::lock_guard lock(mutex_);
    return stopping_;
}

void Worker::RequestStop() {
    {
        std::lock_guard lock(mutex_);
        if (stopping_) return;
        stopping_ = true;
        operations_.clear();
    }
    if (cancel_) cancel_();
    wake_.notify_all();
}

void Worker::Stop() {
    RequestStop();
    Join();
}

void Worker::Join() {
    if (worker_.joinable()) worker_.join();
}

bool Worker::WaitIdle(std::chrono::milliseconds timeout) {
    std::unique_lock lock(mutex_);
    return wake_.wait_for(lock, timeout, [&] {
        return !activity_.busy;
    });
}

void Worker::Run() {
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
