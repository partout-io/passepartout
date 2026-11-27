// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ContextExtensions.h"
#include "AppConstantsResource.h"
#include "CrossConstants.h"
#include "../business/extensions/AppConstantsExtensions.h"
#include "../business/strategy/FakeTunnelStrategy.h"
#include "partout.h"
#include <partout/models/ABIEnvelope.h>
#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <stdexcept>
#ifdef _WIN32
#include "../business/platform/WindowsHttpClient.h"
#include "../business/platform/WindowsPreferencesRepository.h"
#include <partout/winrt/WinRTTunnelStrategy.h>
#else
#include "../business/strategy/FilePreferencesRepository.h"
#include "../business/strategy/OfflineHttpClient.h"
#endif

namespace Passepartout {
#ifdef _WIN32
bool ReviewIssue(const std::string &recipient_address, const Models::Issue &issue);
#endif

Models::Platform::ePlatform ApplicationPlatform() {
#ifdef _WIN32
    return Models::Platform::windows;
#else
    return Models::Platform::unixLike;
#endif
}

Profile ImportProfile(const std::string &text, const std::string &name) {
    std::unique_ptr<char, decltype(&std::free)> json(
        partout_import_profile(text.c_str(), nullptr, name.c_str()), &std::free
    );
    if (!json) throw std::runtime_error("Partout could not import this configuration.");
    try {
        const auto envelope = Partout::Models::ABIEnvelope::FromJson(Partout::Json::Parse(json.get()));
        if (envelope.code || !envelope.payload)
            throw std::runtime_error("Import failed");
        return Profile::FromJson(*envelope.payload);
    } catch (...) {
        // ABI errors and parser details may contain configuration secrets.
        throw std::runtime_error("Partout could not import this configuration.");
    }
}

std::unique_ptr<HttpClient> MakeHttpClient([[maybe_unused]] const Models::AppConstants &constants) {
#ifdef _WIN32
    return std::make_unique<Windows::HttpClient>(Constants::HTTPTimeout(constants.url));
#else
    // FIXME: ###, Implement on .unixLike and remove the corresponding [[maybe_unused]] attributes.
    return std::make_unique<OfflineHttpClient>();
#endif
}

std::unique_ptr<PreferencesRepository> MakePreferencesRepository(
    [[maybe_unused]] const std::filesystem::path &directory,
    const CrossConstantsType &constants
) {
#ifdef _WIN32
    return std::make_unique<Windows::PreferencesRepository>(constants.storage.preferences_key);
#else
    return std::make_unique<FilePreferencesRepository>(directory / constants.storage.preferences_file);
#endif
}

std::unique_ptr<Partout::Tunnel> MakeTunnel([[maybe_unused]] bool demo, [[maybe_unused]] const CrossConstantsType &constants) {
#ifdef _WIN32
    if (!demo) {
        return std::make_unique<Partout::Tunnel>(
            std::make_unique<Partout::WinRTTunnelStrategy>(constants.tunnel.server_uri)
        );
    }
#else
    // FIXME: ###, Implement on .unixLike and remove the corresponding [[maybe_unused]] attributes.
#endif
    return std::make_unique<Partout::Tunnel>(std::make_unique<FakeTunnelStrategy>());
}

bool ReportIssue([[maybe_unused]] const std::string &recipient, [[maybe_unused]] const Models::Issue &issue) {
#ifdef _WIN32
    return ReviewIssue(recipient, issue);
#else
    // FIXME: ###, Implement on .unixLike and remove the corresponding [[maybe_unused]] attributes.
    return false;
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
