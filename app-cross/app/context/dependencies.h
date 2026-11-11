// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "constants.h"
#include "AppConstants.h"
#include "app_constants_resource.h"
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <stdexcept>

namespace Passepartout {
inline Models::AppConstants LoadAppConstants() {
    return Models::AppConstants::FromJson(nlohmann::json::parse(appConstantsResource));
}

inline std::filesystem::path ProfileDirectory(const std::filesystem::path &root,
    const Models::AppConstants &constants, const CrossConstants &crossConstants, bool demo) {
    auto name = constants.containers.local;
    std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    if (demo) name = crossConstants.storage.demoPrefix + name;
    if (name.empty() || name == "." || name == ".." ||
        name.find_first_of("/\\:") != std::string::npos)
        throw std::runtime_error("Invalid profile container name.");
    return root / std::filesystem::u8path(name);
}
}
