// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "business/extensions/AppConstantsExtensions.h"
#include "ScopedLogSink.h"
#include "business/strategy/FilePreferencesRepository.h"
#include "business/managers/ConfigManager.h"
#include "observables/VersionObservable.h"
#include "business/strategy/GitHubConfigStrategy.h"
#include "business/strategy/GitHubReleaseStrategy.h"
#include "business/managers/VersionChecker.h"
#include "observables/DiagnosticsObservable.h"
#include "SettingsResources.h"
#include "context/AppLog.h"
#include "business/extensions/Models+Business.h"
#include "observables/UserPreferencesObservable.h"
#include "observables/ConfigObservable.h"
#include "observables/CreditsObservable.h"
#include "context/ContextExtensions.h"
#include <algorithm>
#include <cassert>
#include <fstream>
#include <iostream>
#include <condition_variable>
#include "Support.h"

namespace {
class MemoryPreferences final : public Passepartout::PreferencesRepository {
public:
    Passepartout::Models::AppPreferences value = Passepartout::Preferences::Defaults();
    bool fails = false;
    Passepartout::Models::AppPreferences Fetch() override {
        return value;
    }

    void Save(const Passepartout::Models::AppPreferences &next) override {
        if (fails) throw std::runtime_error("Save failed");
        value = next;
    }
};
class FakeHttp final : public Passepartout::HttpClient {
public:
    std::string response = "{}";
    bool fails = false;
    unsigned requests = 0;
    bool canceled = false;
    std::string requested_url;
    std::string Get(const std::string &url) override {
        requested_url = url;
        ++requests;
        if (fails) throw std::runtime_error("Offline");
        return response;
    }

    void Cancel() noexcept override {
        canceled = true;
    }
};
class FixedConfig final : public Passepartout::ConfigManagerStrategy {
public:
    std::optional<Passepartout::ConfigBundle> Bundle() override {
        Passepartout::Models::ConfigBundleConfig config;
        config.rate = 100;
        config.minBuild = 7;
        return Passepartout::ConfigBundle{{Passepartout::Models::ConfigFlag::appNotWorking, config}};
    }

    void Cancel() noexcept override {}
};

class FakeVersion final : public Passepartout::VersionCheckerStrategy {
public:
    std::string value = "1.2.3.4";
    bool fails = false;
    unsigned requests = 0;
    unsigned changelog_requests = 0;
    std::function<void()> before_changelog;
    std::string LatestVersion() override {
        ++requests;
        if (fails) throw std::runtime_error("Offline");
        return value;
    }

    std::vector<Passepartout::Models::ChangelogEntry> FetchChangelog(const std::string &build) override {
        ++changelog_requests;
        if (before_changelog) before_changelog();
        if (fails) throw std::runtime_error("Offline");
        return {{1, build, 42}};
    }

    void Cancel() noexcept override {}
};
struct BlockingState {
    std::mutex mutex;
    std::condition_variable changed;
    bool entered = false;
    bool canceled = false;
};
class BlockingHttp final : public Passepartout::HttpClient {
public:
    explicit BlockingHttp(std::shared_ptr<BlockingState> state) : state_(std::move(state)) {}

    std::string Get(const std::string &) override {
        std::unique_lock lock(state_->mutex);
        state_->entered = true;
        state_->changed.notify_all();
        state_->changed.wait(lock, [&] { return state_->canceled; });
        throw std::runtime_error("Canceled");
    }

    void Cancel() noexcept override {
        std::lock_guard lock(state_->mutex);
        state_->canceled = true;
        state_->changed.notify_all();
    }
private:
    std::shared_ptr<BlockingState> state_;
};
template<typename Action>
void Fails(Action action) {
    bool failed = false;
    try {
        action();
    } catch (...) {
        failed = true;
    }
    assert(failed);
}
}

using namespace Passepartout;
int main() {
    InitializeTests();
    const auto directory = std::filesystem::temp_directory_path() /
        ("passepartout-settings-test-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directory(directory);
    try {
        {
            Models::AppConstants_url url{};
            url.timeoutInterval = 1.25;
            assert(Constants::HTTPTimeout(url) == std::chrono::milliseconds(1250));
            Models::AppConstants_websites websites{};
            websites.configTTL = 3600;
            websites.betaTTLFactor = 0.1;
            assert(Constants::ConfigTTL(websites) == std::chrono::seconds(3600));
            websites.partoutURL = "https://example.invalid/";
            websites.homeURL = "https://home.invalid";
            assert(Constants::ConfigURL(websites) == "https://example.invalid/passepartout-config/v1/bundle.json");
            assert(Constants::BlogURL(websites) == "https://example.invalid/blog");
            assert(Constants::FAQURL(websites) == "https://home.invalid/faq");
            Models::AppConstants_github github{};
            github.rawURL = "https://raw.invalid///";
            github.issuesURL = "https://example.invalid/issues/";
            assert(Constants::IssueURL(github, 42) == "https://example.invalid/issues/42");
            assert(Constants::ChangelogURL(github, "4199") == "https://raw.invalid/refs/tags/builds/4199/app-cross/CHANGELOG.txt");
            Models::AppConstants_emails emails{};
            emails.domain = "example.invalid";
            emails.recipients.issues = "support";
            emails.recipients.beta = "beta";
            assert(Constants::IssuesEmail(emails) == "support@example.invalid");
            assert(Constants::BetaEmail(emails) == "beta@example.invalid");
        }

        FilePreferencesRepository repository(directory / "preferences.json");
        auto persisted = repository.Fetch();
        assert(persisted.dnsFallsBack && !persisted.logsPrivateData);
        // The app and tunnel exchange the complete generated preferences model.
        auto shared_preferences = persisted;
        shared_preferences.dnsFallsBack = false;
        shared_preferences.logsPrivateData = true;
        shared_preferences.lastCheckedVersion = "1.2.3";
        const auto decoded_preferences = Models::AppPreferences::FromJson(
            Partout::Json::Parse(shared_preferences.ToJson().Encode())
        );
        assert(decoded_preferences == shared_preferences);
        assert(!decoded_preferences.dnsFallsBack && decoded_preferences.logsPrivateData);
        persisted.dnsFallsBack = false;
        repository.Save(persisted);
        assert(!FilePreferencesRepository(directory / "preferences.json").Fetch().dnsFallsBack);
        auto memory = std::make_unique<MemoryPreferences>();
        auto *backend = memory.get();
        bool permitted = true;
        auto store = std::make_shared<PreferencesStore>(std::move(memory));
        UserPreferencesObservable preferences(store, [&] { return permitted; });
        unsigned notifications = 0;
        preferences.OnChange([&](const auto &value) {
            assert(value.dnsFallsBack == preferences.Snapshot().dnsFallsBack);
            ++notifications;
        });
        assert(notifications == 1);
        preferences.SetDNSFallback(false);
        backend->fails = true;
        Fails([&] { preferences.SetDNSFallback(true); });
        assert(!preferences.Snapshot().dnsFallsBack && notifications == 2);
        backend->fails = false;
        // Background cache writes must survive later UI preference edits.
        store->Update([](auto &value) {
            value.lastCheckedVersionTimestamp = 1234;
            value.lastCheckedVersion = "2.0.0";
        });
        assert(notifications == 2);
        preferences.SetDNSFallback(true);
        assert(backend->value.lastCheckedVersion == "2.0.0");
        assert(backend->value.lastCheckedVersionTimestamp == 1234);
        assert(preferences.Snapshot().lastCheckedVersion == "2.0.0");
        // Concurrent field updates serialize against the latest stored model.
        std::thread cache_writer([&] {
            for (int i = 0; i < 100; ++i) {
                store->Update([](auto &value) {
                    value.lastCheckedVersionTimestamp = value.lastCheckedVersionTimestamp.value_or(0) + 1;
                });
            }
        });
        for (int i = 0; i < 100; ++i) preferences.SetDNSFallback(i % 2 == 0);
        cache_writer.join();
        assert(store->Fetch().lastCheckedVersionTimestamp == 1334);
        assert(!backend->value.dnsFallsBack);
        assert(backend->value.lastCheckedVersion == "2.0.0");
        permitted = false;
        Fails([&] { preferences.SetLogsPrivateData(true); });
        assert(!preferences.Snapshot().logsPrivateData);
        {
            std::ofstream broken(directory / "preferences.json");
            broken << "invalid";
        }
        UserPreferencesObservable broken(std::make_shared<PreferencesStore>(
            std::make_unique<FilePreferencesRepository>(directory / "preferences.json")
        ));
        assert(broken.HasLoadError() && broken.Snapshot().dnsFallsBack);

        ConfigManager fixed(std::make_unique<FixedConfig>(), 7, Models::Platform::windows);
        assert(fixed.Refresh() && fixed.ActiveFlags().count(Models::ConfigFlag::appNotWorking));
        ConfigManager old_build(std::make_unique<FixedConfig>(), 6, Models::Platform::windows);
        assert(old_build.Refresh() && old_build.ActiveFlags().empty());

        auto http = std::make_unique<FakeHttp>();
        auto *remote = http.get();
        remote->response = R"({"futureFlag": {}, "appNotWorking": {"rate":100,"minBuild":7,"platforms":["windows"],"data":{"reason":"test"}}})";
        ConfigManager config(std::make_unique<GitHubConfigStrategy>(std::move(http), "https://example.invalid", std::chrono::seconds(0)), 7, Models::Platform::windows);
        std::vector<Models::Event> config_events;
        const auto config_subscription = config.events.Subscribe([&](const auto &event) { config_events.push_back(event); });
        assert(config.Refresh());
        assert(config_events.size() == 1);
        const auto &refresh = std::get<Models::ConfigEventRefresh>(config_events.back());
        assert(refresh.flags.size() == 1 && refresh.flags.front().value == Models::ConfigFlag::appNotWorking);
        assert(refresh.data.At("appNotWorking").At("reason") == "test");
        assert(config.ActiveFlags().at(Models::ConfigFlag::appNotWorking).At("reason") == "test");
        remote->fails = true;
        Fails([&] { config.Refresh(); });
        assert(config.ActiveFlags().size() == 1);
        assert(config_events.size() == 1);
        remote->fails = false;
        for (const auto &value : {R"({"rate":99})", R"({"rate":100,"minBuild":8})", R"({"rate":100,"platforms":["android"]})"}) {
            remote->response = std::string("{\"appNotWorking\":") + value + "}";
            const auto count = config_events.size();
            assert(config.Refresh() && config.ActiveFlags().empty());
            assert(config_events.size() == count + 1);
            const auto &empty = std::get<Models::ConfigEventRefresh>(config_events.back());
            assert(empty.flags.empty() && empty.data.IsObject() && empty.data.Size() == 0);
        }
        config.events.Unsubscribe(config_subscription);
        const auto config_event_count = config_events.size();
        assert(config.Refresh());
        assert(config_events.size() == config_event_count);
        for (const auto platform : {Models::Platform::windows, Models::Platform::unixLike}) {
            auto platform_http = std::make_unique<FakeHttp>();
            auto *platform_remote = platform_http.get();
            ConfigManager platform_config(std::make_unique<GitHubConfigStrategy>(std::move(platform_http),
                "https://example.invalid", std::chrono::seconds(0)), 7, platform
            );
            for (const auto target : {"windows", "unixLike"}) {
                platform_remote->response = std::string("{\"appNotWorking\":{\"rate\":100,\"platforms\":[\"") + target + "\"]}}";
                assert(platform_config.Refresh());
                const bool expected = (platform == Models::Platform::windows) == (std::string(target) == "windows");
                assert(!platform_config.ActiveFlags().empty() == expected);
            }
            platform_remote->response = R"({"appNotWorking":{"rate":100}})";
            assert(platform_config.Refresh() && !platform_config.ActiveFlags().empty());
            platform_remote->response = R"({"appNotWorking":{"rate":100,"platforms":[]}})";
            assert(platform_config.Refresh() && platform_config.ActiveFlags().empty());
        }
        {
            auto client = std::make_unique<FakeHttp>();
            auto *remote = client.get();
            remote->response = R"({"appNotWorking":{"rate":100,"data":{"reason":"test"}}})";
            auto manager = std::make_unique<ConfigManager>(std::make_unique<GitHubConfigStrategy>(
                std::move(client), "https://example.invalid", std::chrono::seconds(0)
            ), 7, Models::Platform::windows);
            assert(manager->Refresh());
            auto *config_manager = manager.get();
            ConfigObservable observable(std::move(manager));
            assert(observable.Snapshot().flags.at(Models::ConfigFlag::appNotWorking).At("reason") == "test");
            remote->response = "{}";
            assert(config_manager->Refresh());
            assert(observable.Snapshot().flags.empty());
            remote->response = R"({"appNotWorking":{"rate":100,"data":{"reason":"test"}}})";
            assert(config_manager->Refresh());
            assert(observable.Snapshot().flags.count(Models::ConfigFlag::appNotWorking));
            const auto refresh = [&] {
                observable.Refresh();
                const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(2);
                while (observable.Snapshot().refreshing && std::chrono::steady_clock::now() < deadline) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(1));
                }
                assert(!observable.Snapshot().refreshing);
                return observable.Snapshot();
            };
            remote->fails = true;
            auto state = refresh();
            assert(state.operation_failed);
            assert(state.flags.at(Models::ConfigFlag::appNotWorking).At("reason") == "test");
            remote->fails = false;
            remote->response = "{}";
            state = refresh();
            assert(!state.operation_failed && state.flags.empty());
        }

        auto throttled_http = std::make_unique<FakeHttp>();
        auto *throttled_remote = throttled_http.get();
        ConfigManager throttled(std::make_unique<GitHubConfigStrategy>(std::move(throttled_http), "https://example.invalid", std::chrono::hours(1)), 7, Models::Platform::windows);
        throttled_remote->response = "[]";
        Fails([&] { throttled.Refresh(); });
        throttled_remote->response = "{}";
        assert(throttled.Refresh() && !throttled.Refresh() && throttled_remote->requests == 2);
        auto blocked = std::make_shared<BlockingState>();
        {
            ConfigObservable observable(std::make_unique<ConfigManager>(std::make_unique<GitHubConfigStrategy>(std::make_unique<BlockingHttp>(blocked),
                "https://example.invalid", std::chrono::hours(1)), 7, Models::Platform::windows));
            observable.Refresh();
            std::unique_lock lock(blocked->mutex);
            assert(blocked->changed.wait_for(lock, std::chrono::seconds(2), [&] { return blocked->entered; }));
        }
        assert(blocked->canceled); // Destruction cancels before joining the blocked worker.

        auto release_http = std::make_unique<FakeHttp>();
        auto *release_remote = release_http.get();
        GitHubReleaseStrategy github(std::move(release_http), "https://example.invalid/releases/latest",
            [](const std::string &build) {
                Models::AppConstants_github constants;
                constants.rawURL = "https://example.invalid";
                return Constants::ChangelogURL(constants, build);
            }
        );
        release_remote->response = R"({"name":"1.2.3.4","tag_name":"unrelated-tag"})";
        assert(github.LatestVersion() == "1.2.3.4");
        assert(release_remote->requested_url == "https://example.invalid/releases/latest");
        for (const auto &response : {"invalid JSON", "[]", "{}", R"({"name":null})", R"({"name":12})"}) {
            release_remote->response = response;
            Fails([&] { github.LatestVersion(); });
        }
        release_remote->fails = true;
        Fails([&] { github.LatestVersion(); });
        Fails([&] { github.FetchChangelog("123"); });
        release_remote->fails = false;
        release_remote->response = "Title\n\n* First (#123)\r\n* Plain\n* Invalid (#oops)\n* Overflow (#999999999999999)\nIgnored\n";
        const auto entries = github.FetchChangelog("123");
        assert(release_remote->requested_url == "https://example.invalid/refs/tags/builds/123/app-cross/CHANGELOG.txt");
        assert(entries.size() == 4 && entries[0].id == 1);
        assert(entries[0].comment == "First" && entries[0].issue == 123);
        assert(entries[1].comment == "Plain" && !entries[1].issue);
        assert(entries[2].comment == "Invalid (#oops)" && !entries[2].issue);
        assert(!entries[3].issue);
        release_remote->response = "Title\n\n";
        assert(github.FetchChangelog("124").empty());
        github.Cancel();
        assert(release_remote->canceled);

        auto strategy = std::make_unique<FakeVersion>();
        auto *releases = strategy.get();
        std::optional<std::string> stored;
        VersionChecker version("1.0.0.0", std::move(strategy), "https://example.invalid/windows", 60, {}, {},
            [&](auto, auto value) { stored = std::move(value); });
        std::vector<Models::Event> version_events;
        const auto version_subscription = version.events.Subscribe([&](const auto &event) { version_events.push_back(event); });
        version.Check(100000);
        assert(version_events.size() == 1);
        const auto &release_event = std::get<Models::VersionEventNew>(version_events.back());
        assert(release_event.release.version.major == 1 && release_event.release.version.minor == 2 &&
            release_event.release.version.patch == 3);
        assert(release_event.release.url == "https://example.invalid/windows");
        assert(stored == "1.2.3.4" && version.Snapshot().latest == stored);
        version.Check(101000);
        assert(releases->requests == 1);
        assert(version_events.size() == 2);
        releases->fails = true;
        Fails([&] { version.Check(200000); });
        assert(version.Snapshot().latest == stored);
        releases->fails = false;
        releases->value = "not-a-release";
        Fails([&] { version.Check(201000); });
        assert(!stored && !version.Snapshot().latest);
        assert(version_events.size() == 2);
        releases->value = "1.0.0.0";
        version.Check(300000);
        assert(version_events.size() == 2);
        version.events.Unsubscribe(version_subscription);
        releases->value = "2.0.0";
        version.Check(400000);
        assert(version.Snapshot().latest == "2.0.0" && version_events.size() == 2);

        {
            auto strategy = std::make_unique<FakeVersion>();
            auto *remote = strategy.get();
            auto checker = std::make_unique<VersionChecker>(
                "1.0.0", std::move(strategy), "https://example.invalid/download", 0,
                std::nullopt, std::nullopt, [](auto, auto) {}
            );
            auto *manager = checker.get();
            VersionObservable observable(std::move(checker));
            manager->Check(100000);
            assert(observable.Snapshot().release.latest == "1.2.3.4");
            const auto check = [&] {
                observable.Check();
                const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(2);
                while (observable.Snapshot().checking && std::chrono::steady_clock::now() < deadline) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(1));
                }
                assert(!observable.Snapshot().checking);
                return observable.Snapshot();
            };
            remote->value = "1.0.0";
            assert(!check().release.latest);
            remote->value = "2.0.0";
            assert(check().release.latest == "2.0.0");
            remote->fails = true;
            const auto failed = check();
            assert(failed.operation_failed && !failed.release.latest);
            remote->fails = false;
            assert(check().release.latest == "2.0.0");
        }

        {
            // Changelog fetching works independently of update-download availability.
            auto changelog_strategy = std::make_unique<FakeVersion>();
            auto *changelog_remote = changelog_strategy.get();
            changelog_remote->fails = true;
            std::string changelog_log;
            Tests::ScopedLogSink log_sink([&](auto, auto, const std::string &message) {
                changelog_log = message;
            });
            VersionObservable changelog(std::make_unique<VersionChecker>("1.0.0.7", std::move(changelog_strategy),
                "", 60, std::nullopt, std::nullopt, [](auto, auto) {})
            );
            assert(!changelog.Snapshot().available);
            const auto wait_changelog = [&] {
                const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(2);
                while (changelog.Snapshot().changelog.loading && std::chrono::steady_clock::now() < deadline) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(1));
                }
                assert(!changelog.Snapshot().changelog.loading);
            };
            changelog.LoadChangelog("7");
            wait_changelog();
            assert(changelog.Snapshot().changelog.operation_failed);
            assert(changelog.Snapshot().changelog.entries.empty());
            assert(changelog_log == "Unable to load changelog for build 7");
            changelog_remote->fails = false;
            changelog.LoadChangelog("7");
            wait_changelog();
            assert(!changelog.Snapshot().changelog.operation_failed);
            assert(changelog.Snapshot().changelog.entries[0].comment == "7");
            changelog.LoadChangelog("7");
            wait_changelog();
            assert(changelog_remote->changelog_requests == 3); // Reopening refetches successful content.
            assert(changelog_remote->requests == 0); // Never requests the latest release for a changelog.
            changelog.LoadChangelog("8");
            wait_changelog();
            assert(changelog.Snapshot().changelog.build == "8");
            assert(changelog.Snapshot().changelog.entries[0].comment == "8");
            assert(changelog_remote->changelog_requests == 4);

            auto blocked_changelog = std::make_shared<BlockingState>();
            {
                VersionObservable pending(std::make_unique<VersionChecker>("1.0.0.7",
                    std::make_unique<GitHubReleaseStrategy>(std::make_unique<BlockingHttp>(blocked_changelog),
                        "https://example.invalid/releases/latest", [](const std::string &) {
                            return "https://example.invalid/changelog";
                        }), "", 60, std::nullopt, std::nullopt, [](auto, auto) {})
                );
                pending.LoadChangelog("7");
                std::unique_lock lock(blocked_changelog->mutex);
                assert(blocked_changelog->changed.wait_for(lock, std::chrono::seconds(2), [&] {
                    return blocked_changelog->entered;
                }));
            }
            assert(blocked_changelog->canceled);

        }

        {
            // A newer build supersedes an in-flight response without publishing stale entries.
            std::mutex gate_mutex;
            std::condition_variable gate_changed;
            unsigned entered = 0;
            unsigned released = 0;
            auto strategy = std::make_unique<FakeVersion>();
            auto *remote = strategy.get();
            strategy->before_changelog = [&] {
                std::unique_lock lock(gate_mutex);
                const auto request = ++entered;
                gate_changed.notify_all();
                gate_changed.wait(lock, [&] { return released >= request; });
            };
            VersionObservable changelog(std::make_unique<VersionChecker>(
                "1.0.0", std::move(strategy), "", 60, std::nullopt, std::nullopt, [](auto, auto) {}
            ));
            changelog.LoadChangelog("7");
            {
                std::unique_lock lock(gate_mutex);
                assert(gate_changed.wait_for(lock, std::chrono::seconds(2), [&] { return entered == 1; }));
            }
            changelog.LoadChangelog("8");
            changelog.LoadChangelog("8");
            {
                std::unique_lock lock(gate_mutex);
                released = 1;
                gate_changed.notify_all();
                assert(gate_changed.wait_for(lock, std::chrono::seconds(2), [&] { return entered == 2; }));
                const auto state = changelog.Snapshot().changelog;
                assert(state.build == "8" && state.loading && state.entries.empty());
                released = 2;
                gate_changed.notify_all();
            }
            const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(2);
            while (changelog.Snapshot().changelog.loading && std::chrono::steady_clock::now() < deadline) {
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
            }
            const auto state = changelog.Snapshot().changelog;
            assert(!state.loading && !state.operation_failed);
            assert(state.build == "8" && state.entries.front().comment == "8");
            assert(remote->changelog_requests == 2);
        }

        CreditsObservable credits(CreditsResource, std::make_unique<FakeHttp>(), Models::Platform::unixLike);
        assert(!credits.HasLoadError());
        assert(!credits.Snapshot().licenses.empty());
        Models::Credits sample;
        sample.licenses = {
            {"Common", std::nullopt, "MIT", "https://example.com/common"},
            {"Windows", std::vector<Models::Platform>{{Models::Platform::windows}}, "MIT", "https://example.com/windows"},
            {"Unix", std::vector<Models::Platform>{{Models::Platform::unixLike}}, "MIT", "https://example.com/unix"},
            {"Hidden", std::vector<Models::Platform>{}, "MIT", "https://example.com/hidden"}
        };
        sample.licenses.push_back({"alpha", std::nullopt, "MIT", "https://example.com/alpha"});
        sample.licenses.push_back({"ALPHA", std::nullopt, "MIT", "https://example.com/upper-alpha"});
        sample.notices = {{"Zulu", "last"}, {"beta", "second"}, {"Alpha", "first"}};
        const auto resource = sample.ToJson().Encode();
        CreditsObservable windows_credits(resource, std::make_unique<FakeHttp>(), Models::Platform::windows);
        CreditsObservable unix_credits(resource, std::make_unique<FakeHttp>(), Models::Platform::unixLike);
        assert(!windows_credits.HasLoadError() && !unix_credits.HasLoadError());
        assert(windows_credits.Snapshot().licenses.size() == 4);
        assert(windows_credits.Snapshot().licenses[2].name == "Common");
        assert(windows_credits.Snapshot().licenses[3].name == "Windows");
        assert(unix_credits.Snapshot().licenses.size() == 4);
        assert(unix_credits.Snapshot().licenses[2].name == "Common");
        assert(unix_credits.Snapshot().licenses[3].name == "Unix");
        assert(unix_credits.Snapshot().licenses[0].name == "alpha");
        assert(unix_credits.Snapshot().licenses[1].name == "ALPHA");
        assert(unix_credits.Snapshot().notices[0].name == "Alpha");
        assert(unix_credits.Snapshot().notices[1].name == "beta");
        assert(unix_credits.Snapshot().notices[2].name == "Zulu");
        {
            auto client = std::make_unique<FakeHttp>();
            auto *remote = client.get();
            remote->response.clear();
            remote->fails = true;
            CreditsObservable cached_credits(resource, std::move(client), Models::Platform::unixLike);
            const std::string url = "https://example.com/common";
            const auto load_license = [&] {
                cached_credits.LoadLicense(url);
                const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(2);
                while (cached_credits.License(url).loading && std::chrono::steady_clock::now() < deadline) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(1));
                }
                assert(!cached_credits.License(url).loading);
                return cached_credits.License(url);
            };
            assert(!cached_credits.License(url).loaded);
            auto content = load_license();
            assert(content.operation_failed && !content.loaded);
            assert(remote->requests == 1);
            remote->fails = false;
            content = load_license();
            assert(content.loaded && !content.operation_failed && content.text.empty());
            assert(remote->requests == 2);
            content = load_license();
            assert(content.loaded && content.text.empty());
            assert(remote->requests == 2);
        }
        {
            unsigned calls = 0;
            Tests::ScopedLogSink outer([&](AppLog::Level, AppLog::Category, const std::string &) {
                ++calls;
            });
            AppLog::Write(AppLog::Level::info, AppLog::Category::core, "outer");
            try {
                Tests::ScopedLogSink inner([](AppLog::Level, AppLog::Category, const std::string &) {
                    throw std::runtime_error("Sink failure");
                });
                AppLog::Write(AppLog::Level::info, AppLog::Category::core, "must not throw");
                throw std::runtime_error("Unwind sink scope");
            } catch (const std::runtime_error &) {}
            AppLog::Write(AppLog::Level::info, AppLog::Category::core, "restored");
            assert(calls == 2);
            std::vector<std::thread> writers;
            for (int i = 0; i < 4; ++i) {
                writers.emplace_back([] {
                    for (int j = 0; j < 100; ++j) {
                        AppLog::Write(AppLog::Level::debug, AppLog::Category::core, "concurrent");
                    }
                });
            }
            for (auto &writer : writers) writer.join();
            assert(calls == 402);
        }
        // Leaving the override restores the default runtime buffer sink.
        AppLog::SetPrivateData(false);
        AppLog::Write(AppLog::Level::info, AppLog::Category::core, "public marker");
        AppLog::SetPrivateData(true);
        AppLog::Write(AppLog::Level::info, AppLog::Category::core, "private marker");
        AppLog::SetPrivateData(false);
        assert(AppLog::RuntimeLog().find("private marker") != std::string::npos);
        assert(AppLog::RuntimeLog(false).find("private marker") == std::string::npos);
        Models::Issue issue;
        issue.comment = "café 日本語 $osLine";
        issue.osLine = "Test OS";
        issue.purchasedProducts = {"premium"};
        assert(Issues::Body(issue, "$comment|$appLine|$osLine|$deviceLine|$purchasedProducts|$unknown")
            == "café 日本語 $osLine|unknown|Test OS|unknown|[\"premium\"]|$unknown");
        assert(Issues::Subject(issue) == "Passepartout");
        issue.appLine = "Passepartout 0.1.0.7";
        assert(Issues::Subject(issue) == "Passepartout 0.1.0.7");
        const auto body = Issues::Body(issue, IssueTemplateResource);
        assert(body.find("Hi,\n\ncafé 日本語 $osLine") == 0);
        assert(body.find("App: Passepartout 0.1.0.7\nOS: Test OS") != std::string::npos);

        DiagnosticsObservable diagnostics([&](const Models::Issue &report) {
            assert(report.comment == "Unicode: café 日本語 $osLine");
            assert(report.appLine == "Test App 0.1.0 (4199)");
            assert(Issues::Body(report, IssueTemplateResource).find("Test App 0.1.0 (4199)") != std::string::npos);
            assert(report.attachments.size() == 1);
            const auto &attachment = report.attachments.back();
            assert(attachment.filename == "app.log");
            assert(attachment.content.find("public marker") != std::string::npos);
            assert(attachment.content.find("private marker") == std::string::npos);
            return false; // No mail provider.
        });
        assert(!diagnostics.Report("Unicode: café 日本語 $osLine", {"Test App", "0.1.0", 4199}, "app.log"));
    } catch (const std::exception &error) {
        std::cerr << error.what() << std::endl;
        std::filesystem::remove_all(directory);
        return 1;
    }
    std::filesystem::remove_all(directory);
    std::cout << "Preferences, configuration, versions, cancellation and report preparation passed.\n";
}
