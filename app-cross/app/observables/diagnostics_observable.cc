// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "diagnostics_observable.h"
#include "../business/logging.h"

namespace Passepartout {
DiagnosticsObservable::DiagnosticsObservable(std::unique_ptr<IssueReporter> reporter) : reporter_(std::move(reporter)) {}
std::string DiagnosticsObservable::ApplicationLog() const {
    return AppLogger::RuntimeLog();
}
std::optional<std::string> DiagnosticsObservable::TunnelLog() const {
    // The isolated VPN host uses Windows channel diagnostics and debugger output.
    // Never substitute frontend logs or retained files for another process's log.
    return {};
}
bool DiagnosticsObservable::Report(const std::string &comment) {
    return reporter_->Report(comment, AppLogger::RuntimeLog(false));
}
}
