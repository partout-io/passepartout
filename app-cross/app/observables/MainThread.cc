// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "MainThread.h"
#include <cassert>
#include <thread>

namespace {
const auto MainThreadId = std::this_thread::get_id();
std::function<void(std::function<void()>)> Dispatch;
}

namespace Passepartout {
MainThread::MainThread() : lifetime_(std::make_shared<Lifetime>()) {
    Assert();
}

MainThread::~MainThread() {
    Assert();
}

void MainThread::Assert() {
    assert(std::this_thread::get_id() == MainThreadId);
}

void MainThread::SetDispatcher(std::function<void(std::function<void()>)> dispatch) {
    Assert();
    Dispatch = std::move(dispatch);
}

void MainThread::Post(std::function<void()> action) const {
    if (std::this_thread::get_id() == MainThreadId) {
        action();
        return;
    }
    assert(Dispatch);
    Dispatch([lifetime = std::weak_ptr<Lifetime>(lifetime_), action = std::move(action)] {
        Assert();
        if (!lifetime.expired()) action();
    });
}
}
