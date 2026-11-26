// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppConstants.h"
#include "CrossConstants.h"
#include <filesystem>

namespace Passepartout::Constants {
Models::AppConstants Load();
}

namespace Passepartout::Profiles {
std::filesystem::path Directory(const std::filesystem::path &root,
    const Models::AppConstants &constants, const CrossConstantsType &cross_constants, bool demo
);
}
