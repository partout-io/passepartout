// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "CrossConstants.h"
#include "AppConstants.h"
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <stdexcept>

namespace Passepartout::Profiles {
inline std::filesystem::path Directory(const std::filesystem::path &root,
    const Models::AppConstants &constants, const CrossConstants &cross_constants, bool demo
) {
    auto name = constants.containers.local;
    std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    if (demo) name = cross_constants.storage.demo_prefix + name;
    if (name.empty() || name == "." || name == ".." ||
        name.find_first_of("/\\:") != std::string::npos)
        throw std::runtime_error("Invalid profile container name.");
    return root / std::filesystem::u8path(name);
}
}
