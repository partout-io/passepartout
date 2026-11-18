// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "BackgroundWorker.h"

namespace Passepartout {
BackgroundWorker::BackgroundWorker(std::function<void()> cancel) : cancel_(std::move(cancel)), worker_([this] {
    Run();
}) {}
BackgroundWorker::~BackgroundWorker() {
    Stop();
}
bool BackgroundWorker::Post(std::function<void()> operation) {
    std::lock_guard lock(mutex_);
    if (stopping_) return false;
    operations_.push_back(std::move(operation));
    wake_.notify_one();
    return true;
}
void BackgroundWorker::Stop() {
    {
        std::lock_guard lock(mutex_);
        if (stopping_) return;
        stopping_ = true;
        operations_.clear();
    }
    if (cancel_) cancel_();
    wake_.notify_all();
    if (worker_.joinable()) worker_.join();
}
void BackgroundWorker::Run() {
    for (;;) {
        std::function<void()> operation;
        {
            std::unique_lock lock(mutex_);
            wake_.wait(lock, [this] {
                return stopping_ || !operations_.empty();
            });
            if (stopping_) return;
            operation = std::move(operations_.front());
            operations_.pop_front();
        }
        operation();
    }
}
}
