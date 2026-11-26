// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <filesystem>
#include <memory>
#include <vector>
#include "ConfigurationSource.h"
#include <cstddef>

namespace Passepartout {
// A selected batch can own temporary files. Its lifetime extends through the
// queued import, including failures; ordinary command-line files need no cleanup.
struct ConfigurationFiles {
    virtual ~ConfigurationFiles() = default;
    virtual std::size_t Count() const = 0;
    virtual std::size_t SelectionFailures() const = 0;
    virtual ConfigurationSource Read(std::size_t index) const = 0;
    virtual void Cancel() const noexcept = 0;
};
}
