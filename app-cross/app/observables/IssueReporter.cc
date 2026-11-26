// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "IssueReporter.h"
#include "../business/extensions/Models+Business.h"
#include "SettingsResources.h"
#include <stdexcept>

namespace Passepartout {
IssueReporter::IssueReporter(std::string recipient, std::string version, Handoff handoff)
    : recipient_(std::move(recipient)), version_(std::move(version)), handoff_(std::move(handoff)) {}

bool IssueReporter::Report(const std::string &comment, const std::string &runtime_log) {
    if (comment.size() > 64 * 1024) throw std::invalid_argument("The comment is too long.");
    Models::Issue issue;
    issue.comment = comment;
    issue.appLine = "Passepartout " + version_;
    issue.osLine = IssuePlatform;
    issue.attachments.push_back({"application.txt",
        *issue.appLine + "\nPlatform: " + issue.osLine + "\nCrypto: mbedTLS\n"
        "Tunnel runtime log: unavailable in frontend process\n"});
    if (!runtime_log.empty()) {
        issue.attachments.push_back({"runtime.txt", runtime_log});
    }
    return handoff_(recipient_, issue);
}
}
