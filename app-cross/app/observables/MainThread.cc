// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "MainThread.h"
#include <cassert>
#include <deque>
#include <mutex>
#include <thread>

namespace {
const auto MainThreadId = std::this_thread::get_id();
std::mutex QueueMutex;
std::deque<std::function<void()>> Queue;
std::function<void()> Wakeup;
}

namespace Passepartout {
MainThread::MainThread() : lifetime_(std::make_shared<int>(0)) {
    Assert();
}

MainThread::~MainThread() {
    Assert();
}

void MainThread::Assert() {
    assert(std::this_thread::get_id() == MainThreadId);
}

void MainThread::SetWakeup(std::function<void()> wakeup) {
    Assert();
    std::lock_guard lock(QueueMutex);
    Wakeup = std::move(wakeup);
}

void MainThread::Post(std::function<void()> action) const {
    if (std::this_thread::get_id() == MainThreadId) {
        action();
        return;
    }
    std::function<void()> wakeup;
    {
        std::lock_guard lock(QueueMutex);
        Queue.push_back([lifetime = std::weak_ptr<int>(lifetime_), action = std::move(action)] {
            if (!lifetime.expired()) action();
        });
        wakeup = Wakeup;
    }
    if (wakeup) wakeup();
}

void MainThread::Drain() {
    Assert();
    for (;;) {
        std::function<void()> action;
        {
            std::lock_guard lock(QueueMutex);
            if (Queue.empty()) return;
            action = std::move(Queue.front());
            Queue.pop_front();
        }
        action();
    }
}
}
