// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <functional>
#include <string>

namespace Passepartout::AppLog {
enum class Level { debug, info, error };
enum class Category { core, tunnel, profiles, partout };
using Sink = std::function<void(Level, Category, const std::string &)>;

// Empty selects runtime output. Returns the previous sink for restoration.
// Replacement waits for active writes; sinks must not reenter Write or SetSink.
Sink SetSink(Sink sink);
void PartoutMessage(void *context, const char *profile_id, int level, const char *message) noexcept;
void Write(Level level, Category category, const std::string &message) noexcept;
std::string RuntimeLog(bool include_private_data = true);
void SetPrivateData(bool enabled) noexcept;
}
