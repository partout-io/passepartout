// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "DiagnosticsObservable.h"
#include "../context/AppLog.h"
#include "SettingsResources.h"
#include <stdexcept>

namespace {
constexpr std::size_t MaxCommentBytes = 64 * 1024;
}

namespace Passepartout {
DiagnosticsObservable::DiagnosticsObservable(IssueHandoff handoff) : handoff_(std::move(handoff)) {}

std::string DiagnosticsObservable::ApplicationLog() const {
    return AppLog::RuntimeLog();
}

std::optional<std::string> DiagnosticsObservable::TunnelLog() const {
    // FIXME: ###, Tunnel runtime logs are not available to the frontend process.
    return {};
}

bool DiagnosticsObservable::Report(const std::string &comment, const CrossConstantsType::App &app,
                                   const std::string &app_log_filename
) const {
    if (comment.size() > MaxCommentBytes) throw std::invalid_argument("The comment is too long.");
    Models::Issue issue;
    issue.comment = comment;
    issue.appLine = app.name + " " + app.version_number + " (" + std::to_string(app.build_number) + ")";
    issue.osLine = IssuePlatform;
    const auto runtime_log = AppLog::RuntimeLog(false);
    if (!runtime_log.empty()) {
        issue.attachments.push_back({app_log_filename, runtime_log});
    }
    return handoff_(issue);
}
}
