// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "DiagnosticsObservable.h"
#include "../context/AppLog.h"

namespace Passepartout {
DiagnosticsObservable::DiagnosticsObservable(std::unique_ptr<IssueReporter> reporter) : reporter_(std::move(reporter)) {}

std::string DiagnosticsObservable::ApplicationLog() const {
    return AppLog::RuntimeLog();
}

std::optional<std::string> DiagnosticsObservable::TunnelLog() const {
    // FIXME: ###, Tunnel runtime logs are not available to the frontend process.
    return {};
}

bool DiagnosticsObservable::Report(const std::string &comment) {
    return reporter_->Report(comment, AppLog::RuntimeLog(false));
}
}
