// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../models/ConfigBundle.h"
#include <optional>

namespace Passepartout {
class ConfigManagerStrategy {
public:
    virtual ~ConfigManagerStrategy() = default;
    // No bundle means the source is throttled; retain the current active flags.
    virtual std::optional<ConfigBundle> Bundle() = 0;
    virtual void Cancel() noexcept = 0;
};
}
