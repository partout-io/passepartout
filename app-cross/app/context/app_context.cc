// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "app_context.h"
#include "../observables/session.h"
#include "../business/file_profile_repository.h"
#include "../business/file_profile_journal.h"
#include "../business/fake_tunnel_strategy.h"
#include "../business/file_preferences_repository.h"
#include "../platform/windows_tunnel.h"
#include "../platform/windows_http_client.h"
#include "../platform/windows_issue_handoff.h"
#include "settings_resources.h"
#include "import_result.h"
#include "partout.h"
#include <cstdlib>
#include <stdexcept>

namespace Passepartout {
namespace {
class PartoutWireGuardKeyGenerator final : public WireGuardKeyGenerator {
public:
    std::string PublicKey(const std::string &privateKey) const override {
        std::unique_ptr<char, decltype(&std::free)> key(partout_wireguard_pubkey(privateKey.c_str()), &std::free);
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
    if (!demo) return MakeWindowsHttpClient(std::chrono::milliseconds(
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
    return ReviewWindowsIssue(report);
#else
    return false;
#endif
}
Profile ImportProfile(const std::string &text, const std::string &name) {
    std::unique_ptr<char, decltype(&std::free)> json(
        partout_import_profile(text.c_str(), name.c_str()), &std::free);
    return DecodeImportResult(json.get());
}
class UnavailableTunnelStrategy final : public TunnelStrategy {
public:
    std::vector<Models::AppTunnelInfo> Fetch() override {
        throw std::runtime_error("VPN control is only available in the Windows package. Use --demo for UI development.");
    }
    void Save(const Profile &) override {
        Fail();
    }
    void Connect(const std::string &) override {
        Fail();
    }
    void Disconnect(const std::string &) override {
        Fail();
    }
    void Remove(const std::string &) override {
        Fail();
    }
private:
    void Fail() {
        throw std::runtime_error("VPN control is unavailable.");
    }
};
std::unique_ptr<TunnelStrategy> MakeTunnel(bool demo, const CrossConstants &constants, const Models::AppConstants &shared) {
    if (demo) return std::make_unique<FakeTunnelStrategy>();
#ifdef _WIN32
    return MakeWindowsTunnelStrategy(constants.tunnel.serverUri, shared.tunnel.dnsFallbackServers);
#else
    return std::make_unique<UnavailableTunnelStrategy>();
#endif
}
}
AppContext::AppContext(const std::filesystem::path &dataRoot, bool demo,
                       Models::AppConstants appConstants, CrossConstants frontendConstants)
    : constants(std::move(appConstants)), crossConstants(std::move(frontendConstants)),
      applicationVersion(ApplicationVersion()),
      wireGuardKeys(std::make_unique<PartoutWireGuardKeyGenerator>()),
      logger_(std::make_shared<AppLogger>()),
      session_(std::make_unique<AppSession>(std::make_unique<FileProfileRepository>(
          ProfileDirectory(dataRoot, constants, crossConstants, demo)),
          ImportProfile, MakeTunnel(demo, crossConstants, constants), logger_,
          std::make_unique<FileProfileJournal>(ProfileDirectory(dataRoot, constants, crossConstants, demo) / "transactions"))),
      profiles(*session_), tunnel(*session_),
      preferences(std::make_unique<FilePreferencesRepository>(
          ProfileDirectory(dataRoot, constants, crossConstants, demo) / "preferences.json"), [this] {
              const auto state = session_->Snapshot();
              return state.loaded && !state.busy && !state.pendingProfile && state.tunnelAvailable &&
                  state.tunnelObservationErrors.empty() && std::all_of(state.tunnels.begin(), state.tunnels.end(), [](const auto &info) {
                      return info.status.value == Status::disconnected;
                  });
          }),
      config(std::make_unique<ConfigManager>(MakeHttp(constants, demo),
          constants.websites.partoutURL + "/passepartout-config/v1/bundle.json", BuildNumber(applicationVersion),
          std::chrono::seconds(static_cast<std::int64_t>(constants.websites.configTTL * constants.websites.betaTTLFactor)))),
      version(std::make_unique<VersionChecker>(applicationVersion, nullptr, std::string(),
          static_cast<std::int64_t>(constants.url.versionRateLimit), preferences.Snapshot().lastCheckedVersionTimestamp,
          preferences.Snapshot().lastCheckedVersion, [this](auto timestamp, auto latest) {
              preferences.SetLastCheckedVersion(timestamp, std::move(latest));
          }), applicationVersion, changelogResource),
      credits(creditsResource, MakeHttp(constants, demo)),
      diagnostics(std::make_unique<IssueReporter>(constants.emails.recipients.beta + "@" + constants.emails.domain,
          applicationVersion, ReviewIssue)) {
    preferences.OnChange([this](const auto &value) {
        session_->ApplyPreferences(value);
    });
    config.Refresh();
    logger_->Write(LogLevel::info, "core", demo ? "Application mode: demo (FakeTunnel)" : "Application mode: normal (Partout::Tunnel)");
}
AppContext::~AppContext() = default;
}
