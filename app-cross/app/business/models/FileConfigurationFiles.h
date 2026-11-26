// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ConfigurationFiles.h"

namespace Passepartout {
class FileConfigurationFiles final : public ConfigurationFiles {
public:
    explicit FileConfigurationFiles(std::vector<std::filesystem::path> values, std::size_t failures = 0);
    std::size_t Count() const override;
    std::size_t SelectionFailures() const override;
    ConfigurationSource Read(std::size_t index) const override;
    void Cancel() const noexcept override;
    const std::vector<std::filesystem::path> paths;
private:
    const std::size_t failures_;
};
}
