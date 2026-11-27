// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once

namespace Passepartout::Tests {
// Own before observables/workers, so dispatch is installed for their lifetimes.
class MainThreadQueue final {
public:
    MainThreadQueue();
    ~MainThreadQueue();
    MainThreadQueue(const MainThreadQueue &) = delete;
    MainThreadQueue &operator=(const MainThreadQueue &) = delete;
    static void Drain();
};
}
