// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppConstants.h"
#include "Platform.h"
#include <filesystem>
#include <memory>
#include "../business/strategy/HttpClient.h"
#include "../business/strategy/PreferencesRepository.h"
#include <partout/tunnel/Tunnel.h>

namespace Passepartout {
struct CrossConstantsType;
std::unique_ptr<HttpClient> MakeHttpClient(const Models::AppConstants &constants);
std::unique_ptr<Partout::Tunnel> MakeTunnel(bool demo, const CrossConstantsType &constants);
std::unique_ptr<PreferencesRepository> MakePreferencesRepository(
    const std::filesystem::path &directory,
    const CrossConstantsType &constants
);
Models::Platform::ePlatform ApplicationPlatform();
}

namespace Passepartout::Constants {
Models::AppConstants Load();
}

namespace Passepartout::Profiles {
std::filesystem::path Directory(
    const std::filesystem::path &root,
    const Models::AppConstants &constants
);
}
