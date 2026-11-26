// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "MemoryConfigurationFiles.h"
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
}

namespace Passepartout {
std::size_t MemoryConfigurationFiles::SelectionFailures() const {
    return failures_;
}

void MemoryConfigurationFiles::Cancel() const noexcept {}
}
