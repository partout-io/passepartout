// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "context/AppLog.h"

namespace Passepartout::Tests {
// Process-wide override: stop logging workers before this scope ends.
class ScopedLogSink final {
public:
    explicit ScopedLogSink(LogSink sink);
    ~ScopedLogSink();
    ScopedLogSink(const ScopedLogSink &) = delete;
    ScopedLogSink &operator=(const ScopedLogSink &) = delete;
private:
    LogSink previous_;
};
}
