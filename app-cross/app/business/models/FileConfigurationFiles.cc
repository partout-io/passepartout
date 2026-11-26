// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "FileConfigurationFiles.h"
#include "../extensions/Models+Business.h"

namespace Passepartout {
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
