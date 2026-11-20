// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../business/models/ConfigurationFiles.h"

namespace Passepartout {
// Keep failures from individual native file reads separate from batch failures.
template<typename Stage>
ConfigurationFiles CollectConfigurationFiles(std::size_t count, Stage stage) {
    std::vector<std::filesystem::path> paths;
    std::size_t failures = 0;
    for (std::size_t index = 0; index < count; ++index) {
        try {
            paths.push_back(stage(index));
        } catch (...) {
            ++failures;
        }
    }
    return ConfigurationFiles(std::move(paths), failures);
}
}
