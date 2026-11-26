// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AppContext.h"
#include "../business/strategy/GitHubConfigStrategy.h"
#include "../business/strategy/OfflineHttpClient.h"
#include "../business/strategy/PartoutWireGuardKeyGenerator.h"
#include "../context/ContextExtensions.h"
#include "../business/managers/AppSession.h"
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
std::string ApplicationVersion() {
#ifdef PASSEPARTOUT_APP_VERSION
    return PASSEPARTOUT_APP_VERSION;
#else
    return {};
#endif
}

int BuildNumber(const std::string &version) {
    const auto last = version.find_last_of('.');
    try {
        return std::stoi(version.substr(last == std::string::npos ? 0 : last + 1));
    } catch (...) {
        return 0;
    }
}

std::unique_ptr<Passepartout::HttpClient> MakeHttp(const Passepartout::Models::AppConstants &constants) {
#ifdef _WIN32
    return Passepartout::Windows::MakeHttpClient(std::chrono::milliseconds(
        static_cast<std::int64_t>(constants.url.timeoutInterval * 1000)));
#else
    return std::make_unique<Passepartout::OfflineHttpClient>();
#endif
}

bool ReviewIssue(const std::string &recipient, const Passepartout::Models::Issue &issue) {
#ifdef _WIN32
    return Passepartout::Windows::Issue::Review(recipient, issue);
#else
    return false;
#endif
}

Passepartout::Profile ImportProfile(const std::string &text, const std::string &name) {
    std::unique_ptr<char, decltype(&std::free)> json(
        partout_import_profile(text.c_str(), nullptr, name.c_str()), &std::free);
    return Passepartout::Imports::DecodeResult(json.get());
}

std::unique_ptr<Partout::Tunnel> MakeTunnel(bool demo, const Passepartout::CrossConstantsType &constants) {
    if (demo) return std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>());
#ifdef _WIN32
    return std::make_unique<Partout::Tunnel>(
        std::make_unique<Partout::WinRTTunnelStrategy>(constants.tunnel.server_uri)
    );
#else
    return std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>());
#endif
}

std::unique_ptr<Passepartout::PreferencesRepository> MakePreferencesRepository(
    const std::filesystem::path &directory, const Passepartout::CrossConstantsType &constants
) {
#ifdef _WIN32
    return std::make_unique<Passepartout::Windows::PreferencesRepository>(constants.storage.preferences_key);
#else
    return std::make_unique<Passepartout::FilePreferencesRepository>(directory / constants.storage.preferences_file);
#endif
}

void ApplyLoggingPreferences(const Passepartout::Models::AppPreferences &preferences) {
    partout_init_args init{};
    init.log_level = PartoutLogLevelDebug;
    init.logs_private_data = preferences.logsPrivateData;
    init.logger_fn = Passepartout::AppLogger::PartoutMessage;
    if (preferences.logsPrivateData) Passepartout::AppLogger::SetPrivateData(true);
    partout_init(&init);
    if (!preferences.logsPrivateData) Passepartout::AppLogger::SetPrivateData(false);
}
}

using Passepartout::AppContext;

AppContext::AppContext(const std::filesystem::path &data_root, bool demo,
                       Models::AppConstants app_constants, CrossConstantsType frontend_constants
)
    : constants(std::move(app_constants)), cross_constants(std::move(frontend_constants)),
      application_version(ApplicationVersion()),
      wire_guard_keys(std::make_unique<PartoutWireGuardKeyGenerator>()),
      logger_(std::make_shared<AppLogger>()),
      session_(std::make_unique<AppSession>(std::make_unique<FileProfileRepository>(
          Profiles::Directory(data_root, constants)),
          ImportProfile, MakeTunnel(demo, cross_constants), logger_,
          ApplyLoggingPreferences)),
      profiles(*session_), tunnel(*session_),
      preferences(MakePreferencesRepository(
          Profiles::Directory(data_root, constants), cross_constants), [this] {
              const auto state = session_->Snapshot();
              return state.loaded && !state.busy && !state.pending_profile && state.tunnel_available &&
                  state.tunnel_observation_errors.empty() && std::all_of(state.tunnels.begin(), state.tunnels.end(), [](const auto &info) {
                      return info.status.value == Status::disconnected;
                  });
          }),
      config(std::make_unique<ConfigManager>(std::make_unique<GitHubConfigStrategy>(MakeHttp(constants),
          constants.websites.partoutURL + "/passepartout-config/v1/bundle.json",
          std::chrono::seconds(static_cast<std::int64_t>(constants.websites.configTTL * constants.websites.betaTTLFactor))),
          BuildNumber(application_version))),
      version(std::make_unique<VersionChecker>(application_version, nullptr, std::string(),
          static_cast<std::int64_t>(constants.url.versionRateLimit), preferences.Snapshot().lastCheckedVersionTimestamp,
          preferences.Snapshot().lastCheckedVersion, [this](auto timestamp, auto latest) {
              preferences.SetLastCheckedVersion(timestamp, std::move(latest));
          }), application_version, ChangelogResource),
      credits(CreditsResource, MakeHttp(constants)),
      diagnostics(std::make_unique<IssueReporter>(constants.emails.recipients.beta + "@" + constants.emails.domain,
          application_version, ReviewIssue)) {
    preferences.OnChange([this](const auto &value) {
        session_->ApplyPreferences(value);
    });
    config.Refresh();
    logger_->Write(LogLevel::info, LogCategory::core, demo ? "Application mode: demo (FakeTunnel)" : "Application mode: normal (Partout::Tunnel)");
}

AppContext::~AppContext() = default;
