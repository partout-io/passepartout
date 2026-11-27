// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "MainThreadQueue.h"
#include "observables/MainThread.h"
#include <deque>
#include <mutex>

namespace {
std::mutex QueueMutex;
std::deque<std::function<void()>> Queue;
}

namespace Passepartout::Tests {
MainThreadQueue::MainThreadQueue() {
    MainThread::SetDispatcher([](std::function<void()> action) {
        std::lock_guard lock(QueueMutex);
        Queue.push_back(std::move(action));
    });
}

MainThreadQueue::~MainThreadQueue() {
    MainThread::SetDispatcher({});
    Drain();
}

void MainThreadQueue::Drain() {
    MainThread::Assert();
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
