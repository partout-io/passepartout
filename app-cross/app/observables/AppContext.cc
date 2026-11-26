// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../business/extensions/AppConstantsExtensions.h"
#include "AppContext.h"
#include "../context/AppLog.h"
#include "../business/strategy/GitHubReleaseStrategy.h"
#include "../business/strategy/GitHubConfigStrategy.h"
#include "../business/strategy/OfflineHttpClient.h"
#include "../business/strategy/PartoutWireGuardKeyGenerator.h"
#include "../context/ContextExtensions.h"
#include "../business/managers/ProfileManager.h"
#include "../business/strategy/FileProfileRepository.h"
#include "../business/strategy/FakeTunnelStrategy.h"
#include "../business/strategy/FilePreferencesRepository.h"
#include "../business/platform/WindowsHttpClient.h"
#include "../ui/platform/WindowsIssueHandoff.h"
#include "SettingsResources.h"
#include "../business/extensions/Models+Business.h"
#include "partout.h"
#ifdef _WIN32
#include <partout/winrt/WinRTTunnelStrategy.h>
#include "../business/platform/WindowsPreferencesRepository.h"
#endif
#include <cstdlib>
#include <stdexcept>

namespace {
std::unique_ptr<Passepartout::HttpClient> MakeHttp(const Passepartout::Models::AppConstants &constants) {
#ifdef _WIN32
    return Passepartout::Windows::MakeHttpClient(Passepartout::Constants::HTTPTimeout(constants.url));
#else
    // FIXME: ###, Implement on .unixLike
    return std::make_unique<Passepartout::OfflineHttpClient>();
#endif
}

bool ReviewIssue(const std::string &recipient, const Passepartout::Models::Issue &issue) {
#ifdef _WIN32
    return Passepartout::Windows::Issue::Review(recipient, issue);
#else
    // FIXME: ###, Implement on .unixLike
    return false;
#endif
}

Passepartout::Profile ImportProfile(const std::string &text, const std::string &name) {
    std::unique_ptr<char, decltype(&std::free)> json(
        partout_import_profile(text.c_str(), nullptr, name.c_str()), &std::free
    );
    return Passepartout::Imports::DecodeResult(json.get());
}

std::unique_ptr<Partout::Tunnel> MakeTunnel(bool demo, const Passepartout::CrossConstantsType &constants) {
    if (demo) return std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>());
#ifdef _WIN32
    return std::make_unique<Partout::Tunnel>(
        std::make_unique<Partout::WinRTTunnelStrategy>(constants.tunnel.server_uri)
    );
#else
    // FIXME: ###, Implement on .unixLike
    return std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>());
#endif
}

std::unique_ptr<Passepartout::PreferencesRepository> MakePreferencesRepository(
    const std::filesystem::path &directory,
    const Passepartout::CrossConstantsType &constants
) {
#ifdef _WIN32
    return std::make_unique<Passepartout::Windows::PreferencesRepository>(constants.storage.preferences_key);
#else
    return std::make_unique<Passepartout::FilePreferencesRepository>(directory / constants.storage.preferences_file);
#endif
}

}

using Passepartout::AppContext;

AppContext::AppContext(
    const std::filesystem::path &data_root,
    Models::AppConstants app_constants,
    CrossConstantsType frontend_constants,
    bool demo
) :
    constants(std::move(app_constants)),
    cross_constants(std::move(frontend_constants)),
    wireguard_keygen(std::make_unique<PartoutWireGuardKeyGenerator>()),
    profile_manager_(
        std::make_unique<FileProfileRepository>(Profiles::Directory(data_root, constants)),
        ImportProfile
    ),
    profiles(executor_, profile_manager_),
    tunnel(executor_, MakeTunnel(demo, cross_constants), profile_manager_),
    preferences(
        MakePreferencesRepository(Profiles::Directory(data_root, constants), cross_constants),
        [this] {
            const auto state = tunnel.Snapshot();
            return profiles.Snapshot().loaded && !state.busy && !profiles.Snapshot().busy && !state.pending_profile && state.available &&
                state.errors.unobservable_profiles.empty() && std::all_of(
                    state.tunnels.begin(), state.tunnels.end(),
                    [](const auto &info) {
                        return info.status.value == Status::disconnected;
                    }
                );
        }
    ),
    config(
        std::make_unique<ConfigManager>(
            std::make_unique<GitHubConfigStrategy>(
                MakeHttp(constants),
                Constants::ConfigURL(constants.websites),
                Constants::ConfigTTL(constants.websites)
            ),
            cross_constants.app.build_number,
            ApplicationPlatform()
        )
    ),
    version(
        std::make_unique<VersionChecker>(
            cross_constants.app.version_number,
            std::make_unique<GitHubReleaseStrategy>(
                MakeHttp(constants),
                constants.github.latestReleaseURL,
                [github = constants.github](const std::string &build) {
                    return Constants::ChangelogURL(github, build);
                }
            ),
            std::string(),
            static_cast<std::int64_t>(constants.url.versionRateLimit),
            preferences.Snapshot().lastCheckedVersionTimestamp,
            preferences.Snapshot().lastCheckedVersion,
            [this](auto timestamp, auto latest) {
                preferences.SetLastCheckedVersion(timestamp, std::move(latest));
            }
        )
    ),
    credits(CreditsResource, MakeHttp(constants), ApplicationPlatform()),
    diagnostics([recipient = Constants::BetaEmail(constants.emails)](const Models::Issue &issue) {
        return ReviewIssue(recipient, issue);
    }) {
    try {
        // Initialize native logging once from stored preferences, before starting work.
        const bool logs_private_data = preferences.Snapshot().logsPrivateData;
        AppLog::SetPrivateData(logs_private_data);
        partout_init_args init{};
        init.log_level = PartoutLogLevelDebug;
        init.logs_private_data = logs_private_data;
        init.logger_fn = AppLog::PartoutMessage;
        partout_init(&init);
        preferences.OnChange([previous = logs_private_data](const auto &value) mutable {
            if (previous == value.logsPrivateData) return;
            AppLog::SetPrivateData(value.logsPrivateData);
            previous = value.logsPrivateData;
        });
        tunnel.Refresh();
        profiles.Load();
        config.Refresh();
        AppLog::Write(
            AppLog::Level::info,
            AppLog::Category::core,
            demo ? "Application mode: demo (FakeTunnel)" : "Application mode: normal (Partout::Tunnel)"
        );
    } catch (...) {
        executor_.RequestStop();
        profiles.Cancel();
        tunnel.Cancel();
        executor_.Join();
        throw;
    }
}

AppContext::~AppContext() {
    executor_.RequestStop();
    profiles.Cancel();
    tunnel.Cancel();
    executor_.Join();
}
