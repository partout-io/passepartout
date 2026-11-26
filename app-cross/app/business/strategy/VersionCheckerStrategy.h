// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <string>

namespace Passepartout {
class VersionCheckerStrategy {
public:
    virtual ~VersionCheckerStrategy() = default;
    virtual std::string LatestVersion() = 0;
    virtual void Cancel() noexcept = 0;
};
}
