// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "logging.h"
#include "partout.h"
#include <chrono>
#include <iostream>
#include <sstream>
#include <deque>
#include <atomic>
#ifdef _WIN32
#include <windows.h>
#endif

namespace Passepartout {
namespace {
std::mutex runtimeMutex;
struct RuntimeLine {
    std::string text;
    bool isPrivate;
};
std::deque<RuntimeLine> runtimeLines;
std::atomic_bool logsPrivateData{false};
std::size_t runtimeBytes = 0;
constexpr std::size_t maximumLogBytes = 256 * 1024;
}
void AppLogger::SetPrivateData(bool enabled) noexcept {
    logsPrivateData.store(enabled);
}
std::string AppLogger::RuntimeLog(bool includePrivateData) {
    std::lock_guard lock(runtimeMutex);
    std::string result;
    result.reserve(runtimeBytes);
    for (const auto &line : runtimeLines) {
        if (includePrivateData || !line.isPrivate) result += line.text;
    }
    return result;
}
AppLogger::AppLogger(LogSink sink) : sink_(std::move(sink)) {}
void AppLogger::PartoutMessage(void *, const char *profileId, int level, const char *message) noexcept {
    // Partout holds this process-wide callback; no application-owned context may dangle.
    static AppLogger logger;
    if (!message) return;
    try {
        const auto text = profileId && logsPrivateData.load()
            ? "[" + std::string(profileId) + "] " + message : std::string(message);
        const auto logLevel = level <= PartoutLogLevelError ? LogLevel::error
            : level <= PartoutLogLevelInfo ? LogLevel::info
            : LogLevel::debug;
        logger.Write(logLevel, "partout", text);
    } catch (...) {
        // Never throw through the native logging callback.
    }
}
void AppLogger::Write(LogLevel level, const std::string &category, const std::string &message) noexcept {
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
        line << timestamp << " [" << category << "] [" << name << "] " << message << '\n';
        auto text = line.str();
        if (text.size() > maximumLogBytes) text.resize(maximumLogBytes);
        {
            std::lock_guard bufferLock(runtimeMutex);
            while (!runtimeLines.empty() && (runtimeBytes + text.size() > maximumLogBytes || runtimeLines.size() >= 2000)) {
                runtimeBytes -= runtimeLines.front().text.size();
                runtimeLines.pop_front();
            }
            runtimeBytes += text.size();
            runtimeLines.push_back({text, logsPrivateData.load()});
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
}
