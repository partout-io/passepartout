// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Issue.h"
#include "../context/CrossConstants.h"
#include <functional>
#include <string>
#include <optional>

namespace Passepartout {
class DiagnosticsObservable final {
public:
    using IssueHandoff = std::function<bool(const Models::Issue &)>;
    explicit DiagnosticsObservable(IssueHandoff handoff);
    std::string ApplicationLog() const;
    std::optional<std::string> TunnelLog() const;
    // The native handler must present a draft and own temporary attachment files.
    bool Report(const std::string &comment, const CrossConstantsType::App &app,
                const std::string &app_log_filename
    ) const;
private:
    IssueHandoff handoff_;
};
}
