// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "IssueReporter.h"
#include <memory>
#include <optional>

namespace Passepartout {
class DiagnosticsObservable {
public:
    explicit DiagnosticsObservable(std::unique_ptr<IssueReporter> reporter);
    std::string ApplicationLog() const;
    std::optional<std::string> TunnelLog() const;
    bool Report(const std::string &comment);
private:
    std::unique_ptr<IssueReporter> reporter_;
};
}
