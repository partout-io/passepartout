// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AppLog.h"
#include "partout.h"
#include <chrono>
#include <iostream>
#include <sstream>
#include <deque>
#include <atomic>
#include <mutex>
#include <utility>
#ifdef _WIN32
#include <windows.h>
#endif

namespace {
constexpr std::size_t MaximumLogBytes = 256 * 1024;
constexpr std::size_t MaximumLogLines = 2000;

struct RuntimeLine final {
    std::string text;
    bool is_private;
};

struct RuntimeLogState final {
    std::mutex mutex;
    std::deque<RuntimeLine> lines;
    std::atomic_bool includes_private_data{false};
    std::size_t bytes = 0;
};

RuntimeLogState runtime;
std::mutex sink_mutex;
Passepartout::AppLog::Sink sink;

const char *CategoryName(Passepartout::AppLog::Category category) {
    switch (category) {
    case Passepartout::AppLog::Category::core: return "core";
    case Passepartout::AppLog::Category::tunnel: return "tunnel";
    case Passepartout::AppLog::Category::profiles: return "profiles";
    case Passepartout::AppLog::Category::partout: return "partout";
    }
    return "unknown";
}

void WriteRuntime(Passepartout::AppLog::Level level, Passepartout::AppLog::Category category, const std::string &message) {
    const auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    const char *name = level == Passepartout::AppLog::Level::error ? "error" : level == Passepartout::AppLog::Level::info ? "info" : "debug";
    std::ostringstream line;
    line << timestamp << " [" << CategoryName(category) << "] [" << name << "] " << message << '\n';
    auto text = line.str();
    if (text.size() > MaximumLogBytes) text.resize(MaximumLogBytes);
    {
        std::lock_guard buffer_lock(runtime.mutex);
        while (!runtime.lines.empty() && (runtime.bytes + text.size() > MaximumLogBytes || runtime.lines.size() >= MaximumLogLines)) {
            runtime.bytes -= runtime.lines.front().text.size();
            runtime.lines.pop_front();
        }
        runtime.bytes += text.size();
        runtime.lines.push_back({text, runtime.includes_private_data.load()});
    }
#ifdef _WIN32
    OutputDebugStringA(text.c_str());
#else
    std::clog << text;
#endif
}
}

namespace Passepartout::AppLog {

void SetPrivateData(bool enabled) noexcept {
    runtime.includes_private_data.store(enabled);
}

std::string RuntimeLog(bool include_private_data) {
    std::lock_guard lock(runtime.mutex);
    std::string result;
    result.reserve(runtime.bytes);
    for (const auto &line : runtime.lines) {
        if (include_private_data || !line.is_private) result += line.text;
    }
    return result;
}

Sink SetSink(Sink replacement) {
    std::lock_guard lock(sink_mutex);
    return std::exchange(sink, std::move(replacement));
}

void PartoutMessage(void *, const char *profile_id, int level, const char *message) noexcept {
    if (!message) return;
    try {
        const auto text = profile_id && runtime.includes_private_data.load()
            ? "[" + std::string(profile_id) + "] " + message : std::string(message);
        const auto log_level = level <= PartoutLogLevelError ? Level::error
            : level <= PartoutLogLevelInfo ? Level::info
            : Level::debug;
        Write(log_level, Category::partout, text);
    } catch (...) {
        // Never throw through the native logging callback.
    }
}

void Write(Level level, Category category, const std::string &message) noexcept {
    try {
        std::lock_guard lock(sink_mutex);
        if (sink) sink(level, category, message);
        else WriteRuntime(level, category, message);
    } catch (...) {
        // Diagnostics must not affect the operation being observed.
    }
}
}
