// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <functional>
#include <string>

namespace Passepartout {
enum class LogLevel { debug, info, error };
enum class LogCategory { core, tunnel, profiles, partout };
using LogSink = std::function<void(LogLevel, LogCategory, const std::string &)>;

namespace AppLog {
// Empty selects runtime output. Returns the previous sink for restoration.
// Replacement waits for active writes; sinks must not reenter Write or SetSink.
LogSink SetSink(LogSink sink);
void PartoutMessage(void *context, const char *profile_id, int level, const char *message) noexcept;
void Write(LogLevel level, LogCategory category, const std::string &message) noexcept;
std::string RuntimeLog(bool include_private_data = true);
void SetPrivateData(bool enabled) noexcept;
}
}
