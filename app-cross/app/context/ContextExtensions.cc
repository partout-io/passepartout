// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ContextExtensions.h"
#include "AppConstantsResource.h"
#include "../business/extensions/Models+Business.h"
#include <algorithm>
#include <cctype>
#include <stdexcept>

namespace Passepartout::Constants {
Models::AppConstants Load() {
    return Models::AppConstants::FromJson(Partout::Json::Parse(AppConstantsResource));
}
}

namespace Passepartout::Profiles {
std::filesystem::path Directory(
    const std::filesystem::path &root,
    const Models::AppConstants &constants
) {
    auto name = constants.containers.local;
    std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    if (name.empty() || name == "." || name == ".." ||
        name.find_first_of("/\\:") != std::string::npos)
        throw std::runtime_error("Invalid profile container name.");
    return root / Paths::FromUtf8(name);
}
}
