// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <functional>
#include <mutex>
#include <string>

namespace Passepartout {
enum class LogLevel { debug, info, error };
enum class LogCategory { core, tunnel, profiles, partout };
using LogSink = std::function<void(LogLevel, LogCategory, const std::string &)>;
class AppLog final {
public:
    explicit AppLog(LogSink sink = {});
    static void PartoutMessage(void *context, const char *profile_id, int level, const char *message) noexcept;
    void Write(LogLevel level, LogCategory category, const std::string &message) noexcept;
    static std::string RuntimeLog(bool include_private_data = true);
    static void SetPrivateData(bool enabled) noexcept;
private:
    LogSink sink_;
    std::mutex mutex_;
};
}
