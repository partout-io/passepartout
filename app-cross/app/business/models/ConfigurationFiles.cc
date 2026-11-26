// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ConfigurationFiles.h"
#include "../extensions/ModelsExtensions.h"

namespace Passepartout {
std::size_t ConfigurationFiles::Count() const {
    return paths.size();
}

ConfigurationSource ConfigurationFiles::Read(std::size_t index) const {
    const auto &path = paths.at(index);
    return {Profiles::ConfigurationName(path), Profiles::ReadConfiguration(path)};
}

MemoryConfigurationFiles::MemoryConfigurationFiles(std::vector<ConfigurationSource> values, std::size_t failures)
    : ConfigurationFiles({}, failures), sources_(std::move(values)) {}

std::size_t MemoryConfigurationFiles::Count() const {
    return sources_.size();
}

ConfigurationSource MemoryConfigurationFiles::Read(std::size_t index) const {
    return sources_.at(index);
}
}
