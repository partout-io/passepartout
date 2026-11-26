// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "DiagnosticsObservable.h"
#include "../context/AppLog.h"
#include "SettingsResources.h"
#include <stdexcept>

namespace Passepartout {
DiagnosticsObservable::DiagnosticsObservable(std::string recipient, CrossConstantsType::App app,
                                             std::string app_log_filename, Handoff handoff
)
    : recipient_(std::move(recipient)), app_(std::move(app)),
      app_log_filename_(std::move(app_log_filename)), handoff_(std::move(handoff)) {}

std::string DiagnosticsObservable::ApplicationLog() const {
    return AppLog::RuntimeLog();
}

std::optional<std::string> DiagnosticsObservable::TunnelLog() const {
    // FIXME: ###, Tunnel runtime logs are not available to the frontend process.
    return {};
}

bool DiagnosticsObservable::Report(const std::string &comment) {
    if (comment.size() > 64 * 1024) throw std::invalid_argument("The comment is too long.");
    Models::Issue issue;
    issue.comment = comment;
    issue.appLine = app_.name + " " + app_.version_number + " (" + std::to_string(app_.build_number) + ")";
    issue.osLine = IssuePlatform;
    const auto runtime_log = AppLog::RuntimeLog(false);
    if (!runtime_log.empty()) {
        issue.attachments.push_back({app_log_filename_, runtime_log});
    }
    return handoff_(recipient_, issue);
}
}
