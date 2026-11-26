// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Issue.h"
#include <functional>
#include <string>

namespace Passepartout {
class IssueReporter final {
public:
    using Handoff = std::function<bool(const std::string &, const Models::Issue &)>;
    IssueReporter(std::string recipient, std::string version, Handoff handoff);
    // The native handler must present a draft and own temporary attachment files.
    bool Report(const std::string &comment, const std::string &runtime_log);
private:
    std::string recipient_;
    std::string version_;
    Handoff handoff_;
};
}
