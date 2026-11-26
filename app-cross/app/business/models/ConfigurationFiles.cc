// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ConfigurationFiles.h"
#include "../extensions/Models+Business.h"
#include <utility>

namespace Passepartout {
MemoryConfigurationFiles::MemoryConfigurationFiles(std::vector<ConfigurationSource> values, std::size_t failures)
    : sources_(std::move(values)), failures_(failures) {}

std::size_t MemoryConfigurationFiles::Count() const {
    return sources_.size();
}

ConfigurationSource MemoryConfigurationFiles::Read(std::size_t index) const {
    return sources_.at(index);
}
std::size_t MemoryConfigurationFiles::SelectionFailures() const {
    return failures_;
}

void MemoryConfigurationFiles::Cancel() const noexcept {}

FileConfigurationFiles::FileConfigurationFiles(std::vector<std::filesystem::path> values, std::size_t failures)
    : paths(std::move(values)), failures_(failures) {}

std::size_t FileConfigurationFiles::Count() const {
    return paths.size();
}

ConfigurationSource FileConfigurationFiles::Read(std::size_t index) const {
    const auto &path = paths.at(index);
    return {Profiles::ConfigurationName(path), Profiles::ReadConfiguration(path)};
}

std::size_t FileConfigurationFiles::SelectionFailures() const {
    return failures_;
}

void FileConfigurationFiles::Cancel() const noexcept {}
}
