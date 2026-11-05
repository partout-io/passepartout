// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "logging.h"
#include <chrono>
#include <iostream>
#include <sstream>
#ifdef _WIN32
#include <windows.h>
#endif

namespace Passepartout {
AppLogger::AppLogger(LogSink sink) : sink_(std::move(sink)) {}
void AppLogger::PartoutMessage(void *, int level, const char *message) noexcept {
    // Partout holds this process-wide callback; no application-owned context may dangle.
    static AppLogger logger;
    if (message) logger.Write(level <= 1 ? LogLevel::error : level <= 3 ? LogLevel::info : LogLevel::debug,
                              "partout", message);
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
#ifdef _WIN32
        // FIXME: ### Add bounded, redacted persistent diagnostics for failures outside a debugger session.
        OutputDebugStringA(line.str().c_str());
#else
        std::clog << line.str();
#endif
    } catch (...) {
        // Diagnostics must not affect the operation being observed.
    }
}
}
