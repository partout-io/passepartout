// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <functional>
#include <memory>
#include <mutex>
#include <string>

namespace Passepartout {
enum class LogLevel { debug, info, error };
using LogSink = std::function<void(LogLevel, const std::string &, const std::string &)>;
class AppLogger {
public:
    explicit AppLogger(LogSink sink = {});
    static void PartoutMessage(void *context, const char *profileId, int level, const char *message) noexcept;
    void Write(LogLevel level, const std::string &category, const std::string &message) noexcept;
private:
    LogSink sink_;
    std::mutex mutex_;
};
}
