// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ContextExtensions.h"
#include "CrossConstants.h"
#include "../business/extensions/AppConstantsExtensions.h"
#include "../business/strategy/OfflineHttpClient.h"
#include "../business/strategy/FakeTunnelStrategy.h"
#include "../business/strategy/FilePreferencesRepository.h"
#ifdef _WIN32
#include "../business/platform/WindowsHttpClient.h"
#include "../business/platform/WindowsPreferencesRepository.h"
#include <partout/winrt/WinRTTunnelStrategy.h>
#endif
#include "AppConstantsResource.h"
#include "../business/extensions/Models+Business.h"
#include <algorithm>
#include <cctype>
#include <stdexcept>

namespace Passepartout {
std::unique_ptr<HttpClient> MakeHttpClient(const Models::AppConstants &constants) {
#ifdef _WIN32
    return std::make_unique<Windows::HttpClient>(Constants::HTTPTimeout(constants.url));
#else
    // FIXME: ###, Implement on .unixLike
    return std::make_unique<OfflineHttpClient>();
#endif
}

std::unique_ptr<Partout::Tunnel> MakeTunnel(bool demo, const CrossConstantsType &constants) {
    if (demo) return std::make_unique<Partout::Tunnel>(std::make_unique<FakeTunnelStrategy>());
#ifdef _WIN32
    return std::make_unique<Partout::Tunnel>(
        std::make_unique<Partout::WinRTTunnelStrategy>(constants.tunnel.server_uri)
    );
#else
    // FIXME: ###, Implement on .unixLike
    return std::make_unique<Partout::Tunnel>(std::make_unique<FakeTunnelStrategy>());
#endif
}

std::unique_ptr<PreferencesRepository> MakePreferencesRepository(
    const std::filesystem::path &directory,
    const CrossConstantsType &constants
) {
#ifdef _WIN32
    return std::make_unique<Windows::PreferencesRepository>(constants.storage.preferences_key);
#else
    return std::make_unique<FilePreferencesRepository>(directory / constants.storage.preferences_file);
#endif
}


Models::Platform::ePlatform ApplicationPlatform() {
#ifdef _WIN32
    return Models::Platform::windows;
#else
    return Models::Platform::unixLike;
#endif
}
}

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
