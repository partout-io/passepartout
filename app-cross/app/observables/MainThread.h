// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <functional>
#include <memory>

namespace Passepartout {
// One delivery lifetime per observable. The UI installs a wake-up hook; portable
// tests drain the same queue explicitly. Workers never wait for delivery.
class MainThread final {
public:
    MainThread();
    ~MainThread();
    MainThread(const MainThread &) = delete;
    MainThread &operator=(const MainThread &) = delete;
    static void Assert();
    static void SetWakeup(std::function<void()> wakeup);
    static void Drain();
    void Post(std::function<void()> action) const;
private:
    std::shared_ptr<int> lifetime_;
};
}
