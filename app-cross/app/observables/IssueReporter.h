// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <filesystem>
#include <functional>
#include <string>
#include <vector>

namespace Passepartout {
struct IssueReport {
    std::string recipient;
    std::string subject;
    std::string body;
    std::vector<std::filesystem::path> attachments;
};

class IssueReporter {
public:
    using Handoff = std::function<bool(const IssueReport &)>;
    IssueReporter(std::string recipient, std::string version, Handoff handoff);
    // The native handler must present a draft; attachments live through its return.
    bool Report(const std::string &comment, const std::string &runtime_log);
private:
    std::string recipient_;
    std::string version_;
    Handoff handoff_;
};
}
