// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../business/extensions/AppConstantsExtensions.h"
#include "AppContext.h"
#include "AppLog.h"
#include "../business/strategy/GitHubReleaseStrategy.h"
#include "../business/strategy/GitHubConfigStrategy.h"
#include "../business/strategy/PartoutWireGuardKeyGenerator.h"
#include "ContextExtensions.h"
#include "../business/managers/ProfileManager.h"
#include "../business/strategy/FileProfileRepository.h"
#include "SettingsResources.h"
#include "../business/extensions/Models+Business.h"
#include <partout/Runtime.h>
#include <stdexcept>

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
    preferences_store_(std::make_shared<PreferencesStore>(
        MakePreferencesRepository(Profiles::Directory(data_root, constants), cross_constants)
    )),
    profiles(executor_, profile_manager_),
    tunnel(executor_, MakeTunnel(demo, cross_constants), profile_manager_),
    preferences(
        preferences_store_,
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
                MakeHttpClient(constants),
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
                MakeHttpClient(constants),
                constants.github.latestReleaseURL,
                [github = constants.github](const std::string &build) {
                    return Constants::ChangelogURL(github, build);
                }
            ),
            std::string(),
            static_cast<std::int64_t>(constants.url.versionRateLimit),
            preferences.Snapshot().lastCheckedVersionTimestamp,
            preferences.Snapshot().lastCheckedVersion,
            [store = preferences_store_](auto timestamp, auto latest) {
                store->Update([&](auto &value) {
                    value.lastCheckedVersionTimestamp = timestamp;
                    value.lastCheckedVersion = std::move(latest);
                });
            }
        )
    ),
    credits(CreditsResource, MakeHttpClient(constants), ApplicationPlatform()),
    diagnostics([recipient = Constants::BetaEmail(constants.emails)](const Models::Issue &issue) {
        return ReportIssue(recipient, issue);
    }) {
    try {
        // Initialize native logging once from stored preferences, before starting work.
        const bool logs_private_data = preferences.Snapshot().logsPrivateData;
        AppLog::SetPrivateData(logs_private_data);
        Partout::Runtime::InitializationOptions init{};
        init.log_level = Partout::Runtime::LogLevel::Debug;
        init.logs_private_data = logs_private_data;
        init.logger_fn = AppLog::PartoutMessage;
        Partout::Runtime::Initialize(init);
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
