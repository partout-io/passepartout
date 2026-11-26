// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AppLogger.h"
#include "partout.h"
#include <chrono>
#include <iostream>
#include <sstream>
#include <deque>
#include <atomic>
#ifdef _WIN32
#include <windows.h>
#endif

namespace {
std::mutex runtime_mutex;
struct RuntimeLine {
    std::string text;
    bool is_private;
};
std::deque<RuntimeLine> runtime_lines;
std::atomic_bool logs_private_data{false};
std::size_t runtime_bytes = 0;
constexpr std::size_t MaximumLogBytes = 256 * 1024;
const char *CategoryName(Passepartout::LogCategory category) {
    switch (category) {
    case Passepartout::LogCategory::core: return "core";
    case Passepartout::LogCategory::tunnel: return "tunnel";
    case Passepartout::LogCategory::profiles: return "profiles";
    case Passepartout::LogCategory::partout: return "partout";
    }
    return "unknown";
}
}

using Passepartout::AppLogger;

void AppLogger::SetPrivateData(bool enabled) noexcept {
    logs_private_data.store(enabled);
}

std::string AppLogger::RuntimeLog(bool include_private_data) {
    std::lock_guard lock(runtime_mutex);
    std::string result;
    result.reserve(runtime_bytes);
    for (const auto &line : runtime_lines) {
        if (include_private_data || !line.is_private) result += line.text;
    }
    return result;
}

AppLogger::AppLogger(LogSink sink) : sink_(std::move(sink)) {}

void AppLogger::PartoutMessage(void *, const char *profile_id, int level, const char *message) noexcept {
    // Partout holds this process-wide callback; no application-owned context may dangle.
    static AppLogger logger;
    if (!message) return;
    try {
        const auto text = profile_id && logs_private_data.load()
            ? "[" + std::string(profile_id) + "] " + message : std::string(message);
        const auto log_level = level <= PartoutLogLevelError ? LogLevel::error
            : level <= PartoutLogLevelInfo ? LogLevel::info
            : LogLevel::debug;
        logger.Write(log_level, LogCategory::partout, text);
    } catch (...) {
        // Never throw through the native logging callback.
    }
}

void AppLogger::Write(LogLevel level, LogCategory category, const std::string &message) noexcept {
    try {
        std::lock_guard lock(mutex_);
        if (sink_) {
            sink_(level, category, message);
            return;
        }
        const auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
        const char *name = level == LogLevel::error ? "error" : level == LogLevel::info ? "info" : "debug";
        std::ostringstream line;
        line << timestamp << " [" << CategoryName(category) << "] [" << name << "] " << message << '\n';
        auto text = line.str();
        if (text.size() > MaximumLogBytes) text.resize(MaximumLogBytes);
        {
            std::lock_guard buffer_lock(runtime_mutex);
            while (!runtime_lines.empty() && (runtime_bytes + text.size() > MaximumLogBytes || runtime_lines.size() >= 2000)) {
                runtime_bytes -= runtime_lines.front().text.size();
                runtime_lines.pop_front();
            }
            runtime_bytes += text.size();
            runtime_lines.push_back({text, logs_private_data.load()});
        }
#ifdef _WIN32
        OutputDebugStringA(text.c_str());
#else
        std::clog << text;
#endif
    } catch (...) {
        // Diagnostics must not affect the operation being observed.
    }
}
