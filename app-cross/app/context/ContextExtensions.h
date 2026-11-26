// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/extensions/Models+Business.h"
#include "../business/strategy/HttpClient.h"
#include "../business/strategy/PreferencesRepository.h"
#include "AppConstants.h"
#include "Issue.h"
#include "Platform.h"
#include <partout/tunnel/Tunnel.h>
#include <filesystem>
#include <memory>
#include <string>

namespace Passepartout {
struct CrossConstantsType;
Models::Platform::ePlatform ApplicationPlatform();
Profile ImportProfile(const std::string &text, const std::string &name);
std::unique_ptr<HttpClient> MakeHttpClient(const Models::AppConstants &constants);
std::unique_ptr<PreferencesRepository> MakePreferencesRepository(
    const std::filesystem::path &directory,
    const CrossConstantsType &constants
);
std::unique_ptr<Partout::Tunnel> MakeTunnel(bool demo, const CrossConstantsType &constants);
bool ReportIssue(const std::string &recipient, const Models::Issue &issue);
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
