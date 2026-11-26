// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ConfigurationFiles.h"
#include <vector>

namespace Passepartout {
struct MemoryConfigurationFiles final : ConfigurationFiles {
    explicit MemoryConfigurationFiles(std::vector<ConfigurationSource> values, std::size_t failures = 0);
    std::size_t Count() const override;
    std::size_t SelectionFailures() const override;
    void Cancel() const noexcept override;
    ConfigurationSource Read(std::size_t index) const override;
private:
    const std::vector<ConfigurationSource> sources_;
    const std::size_t failures_;
};
}
