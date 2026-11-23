// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AppContext.h"
#include "ProfileDirectory.h"
#include "../business/managers/AppSession.h"
#include "../business/strategy/FileProfileRepository.h"
#include "../business/strategy/FileProfileJournal.h"
#include "../business/strategy/FakeTunnelStrategy.h"
#include "../business/strategy/FilePreferencesRepository.h"
#include "../business/platform/WindowsTunnelPreferences.h"
#include "../business/platform/WindowsHttpClient.h"
#include "../ui/platform/WindowsIssueHandoff.h"
#include "SettingsResources.h"
#include "../business/extensions/DecodeImportResult.h"
#include "partout.h"
#ifdef _WIN32
#include "partout_winrt.h"
#endif
#include <cstdlib>
#include <stdexcept>

namespace Passepartout {
namespace {
class PartoutWireGuardKeyGenerator final : public WireGuardKeyGenerator {
public:
    std::string PublicKey(const std::string &private_key) const override {
        std::unique_ptr<char, decltype(&std::free)> key(partout_wireguard_pubkey(private_key.c_str()), &std::free);
        return key ? std::string(key.get()) : std::string();
    }
};
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
std::unique_ptr<HttpClient> MakeHttp(const Models::AppConstants &constants, bool demo) {
#ifdef _WIN32
    if (!demo) return Windows::MakeHttpClient(std::chrono::milliseconds(
        static_cast<std::int64_t>(constants.url.timeoutInterval * 1000)));
#endif
    class OfflineHttpClient final : public HttpClient {
    public:
        std::string Get(const std::string &) override {
            throw std::runtime_error("Remote services are unavailable in this mode.");
        }
        void Cancel() noexcept override {}
    };
    return std::make_unique<OfflineHttpClient>();
}
bool ReviewIssue(const IssueReport &report) {
#ifdef _WIN32
    return Windows::Issue::Review(report);
#else
    return false;
#endif
}
Profile ImportProfile(const std::string &text, const std::string &name) {
    std::unique_ptr<char, decltype(&std::free)> json(
        partout_import_profile(text.c_str(), nullptr, name.c_str()), &std::free);
    return Imports::DecodeResult(json.get());
}

std::unique_ptr<Partout::Tunnel> MakeTunnel(bool demo, const CrossConstants &constants) {
    if (demo) return std::make_unique<Partout::Tunnel>(std::make_unique<FakeTunnelStrategy>());
#ifdef _WIN32
    return std::make_unique<Partout::Tunnel>(
        std::make_unique<Partout::WinRTTunnelStrategy>(constants.tunnel.server_uri)
    );
#else
    throw std::runtime_error("VPN control is unavailable on this platform.");
#endif
}

std::function<void(const Models::AppPreferences &)> TunnelPreferences(bool demo, const Models::AppConstants &constants) {
#ifdef _WIN32
    if (!demo) return [servers = constants.tunnel.dnsFallbackServers](const auto &preferences) {
        Windows::Tunnel::ApplyPreferences(preferences, servers);
    };
#endif
    return {};
}
}

AppContext::AppContext(const std::filesystem::path &data_root, bool demo,
                       Models::AppConstants app_constants, CrossConstants frontend_constants)
    : constants(std::move(app_constants)), cross_constants(std::move(frontend_constants)),
      application_version(ApplicationVersion()),
      wire_guard_keys(std::make_unique<PartoutWireGuardKeyGenerator>()),
      logger_(std::make_shared<AppLogger>()),
      session_(std::make_unique<AppSession>(std::make_unique<FileProfileRepository>(
          Profiles::Directory(data_root, constants, cross_constants, demo)),
          ImportProfile, MakeTunnel(demo, cross_constants), logger_,
          std::make_unique<FileProfileJournal>(Profiles::Directory(data_root, constants, cross_constants, demo) / "transactions"),
          std::chrono::seconds(1), TunnelPreferences(demo, constants))),
      profiles(*session_), tunnel(*session_),
      preferences(std::make_unique<FilePreferencesRepository>(
          Profiles::Directory(data_root, constants, cross_constants, demo) / "preferences.json"), [this] {
              const auto state = session_->Snapshot();
              return state.loaded && !state.busy && !state.pending_profile && state.tunnel_available &&
                  state.tunnel_observation_errors.empty() && std::all_of(state.tunnels.begin(), state.tunnels.end(), [](const auto &info) {
                      return info.status.value == Status::disconnected;
                  });
          }),
      config(std::make_unique<ConfigManager>(MakeHttp(constants, demo),
          constants.websites.partoutURL + "/passepartout-config/v1/bundle.json", BuildNumber(application_version),
          std::chrono::seconds(static_cast<std::int64_t>(constants.websites.configTTL * constants.websites.betaTTLFactor)))),
      version(std::make_unique<VersionChecker>(application_version, nullptr, std::string(),
          static_cast<std::int64_t>(constants.url.versionRateLimit), preferences.Snapshot().lastCheckedVersionTimestamp,
          preferences.Snapshot().lastCheckedVersion, [this](auto timestamp, auto latest) {
              preferences.SetLastCheckedVersion(timestamp, std::move(latest));
          }), application_version, ChangelogResource),
      credits(CreditsResource, MakeHttp(constants, demo)),
      diagnostics(std::make_unique<IssueReporter>(constants.emails.recipients.beta + "@" + constants.emails.domain,
          application_version, ReviewIssue)) {
    preferences.OnChange([this](const auto &value) {
        session_->ApplyPreferences(value);
    });
    config.Refresh();
    logger_->Write(LogLevel::info, LogCategory::core, demo ? "Application mode: demo (FakeTunnel)" : "Application mode: normal (Partout::Tunnel)");
}
AppContext::~AppContext() = default;
}
