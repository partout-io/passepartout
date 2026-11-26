// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ScopedLogSink.h"
#include <utility>

namespace Passepartout::Tests {
ScopedLogSink::ScopedLogSink(LogSink sink) : previous_(AppLog::SetSink(std::move(sink))) {}

ScopedLogSink::~ScopedLogSink() {
    AppLog::SetSink(std::move(previous_));
}
}
