// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <filesystem>
#include <memory>
#include <vector>
#include <string>

namespace Passepartout {
struct ConfigurationSource {
    std::string name;
    std::string text;
};
// A selected batch can own temporary files. Its lifetime extends through the
// queued import, including failures; ordinary command-line files need no cleanup.
struct ConfigurationFiles {
    explicit ConfigurationFiles(std::vector<std::filesystem::path> values, std::size_t failures = 0)
        : paths(std::move(values)), selectionFailures(failures) {}
    virtual ~ConfigurationFiles() = default;
    virtual std::size_t Count() const;
    virtual ConfigurationSource Read(std::size_t index) const;
    virtual void Cancel() const noexcept {}
    const std::vector<std::filesystem::path> paths;
    const std::size_t selectionFailures;
};
struct MemoryConfigurationFiles final : ConfigurationFiles {
    explicit MemoryConfigurationFiles(std::vector<ConfigurationSource> values, std::size_t failures = 0);
    std::size_t Count() const override;
    ConfigurationSource Read(std::size_t index) const override;
private:
    const std::vector<ConfigurationSource> sources_;
};
}
