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
    std::string LatestVersion() override {
        ++requests;
        if (fails) throw std::runtime_error("Offline");
        return value;
    }

    std::vector<Passepartout::Models::ChangelogEntry> FetchChangelog(const std::string &build) override {
        ++changelog_requests;
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
        UserPreferencesObservable preferences(std::move(memory), [&] { return permitted; });
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
        permitted = false;
        Fails([&] { preferences.SetLogsPrivateData(true); });
        assert(!preferences.Snapshot().logsPrivateData);
        {
            std::ofstream broken(directory / "preferences.json");
            broken << "invalid";
        }
        UserPreferencesObservable broken(std::make_unique<FilePreferencesRepository>(directory / "preferences.json"));
        assert(broken.HasLoadError() && broken.Snapshot().dnsFallsBack);

        ConfigManager fixed(std::make_unique<FixedConfig>(), 7, Models::Platform::windows);
        assert(fixed.Refresh() && fixed.ActiveFlags().count(Models::ConfigFlag::appNotWorking));
        ConfigManager old_build(std::make_unique<FixedConfig>(), 6, Models::Platform::windows);
        assert(old_build.Refresh() && old_build.ActiveFlags().empty());

        auto http = std::make_unique<FakeHttp>();
        auto *remote = http.get();
        remote->response = R"({"futureFlag": {}, "appNotWorking": {"rate":100,"minBuild":7,"platforms":["windows"],"data":{"reason":"test"}}})";
        ConfigManager config(std::make_unique<GitHubConfigStrategy>(std::move(http), "https://example.invalid", std::chrono::seconds(0)), 7, Models::Platform::windows);
        assert(config.Refresh());
        assert(config.ActiveFlags().at(Models::ConfigFlag::appNotWorking).At("reason") == "test");
        remote->fails = true;
        Fails([&] { config.Refresh(); });
        assert(config.ActiveFlags().size() == 1);
        remote->fails = false;
        for (const auto &value : {R"({"rate":99})", R"({"rate":100,"minBuild":8})", R"({"rate":100,"platforms":["android"]})"}) {
            remote->response = std::string("{\"appNotWorking\":") + value + "}";
            assert(config.Refresh() && config.ActiveFlags().empty());
        }
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
        version.Check(100000);
        assert(stored == "1.2.3.4" && version.Snapshot().latest == stored);
        version.Check(101000);
        assert(releases->requests == 1);
        releases->fails = true;
        Fails([&] { version.Check(200000); });
        assert(version.Snapshot().latest == stored);
        releases->fails = false;
        releases->value = "not-a-release";
        Fails([&] { version.Check(201000); });
        assert(!stored && !version.Snapshot().latest);

        {
            // Changelog fetching works independently of update-download availability.
            auto changelog_strategy = std::make_unique<FakeVersion>();
            auto *changelog_remote = changelog_strategy.get();
            changelog_remote->fails = true;
            Models::AppConstants_github github_constants;
            github_constants.issuesURL = "https://example.invalid/issues";
            std::string changelog_log;
            Tests::ScopedLogSink log_sink([&](auto, auto, const std::string &message) {
                changelog_log = message;
            });
            VersionObservable changelog(std::make_unique<VersionChecker>("1.0.0.7", std::move(changelog_strategy),
                "", 60, std::nullopt, std::nullopt, [](auto, auto) {}), "1.0.0.7", "7", github_constants
            );
            assert(!changelog.Snapshot().available);
            const auto wait_changelog = [&] {
                const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(2);
                while (changelog.Snapshot().changelog.loading && std::chrono::steady_clock::now() < deadline) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(1));
                }
                assert(!changelog.Snapshot().changelog.loading);
            };
            changelog.LoadChangelog();
            wait_changelog();
            assert(changelog.Snapshot().changelog.operation_failed);
            assert(changelog.Snapshot().changelog.entries.empty());
            assert(changelog_log == "Unable to load changelog for build 7");
            changelog_remote->fails = false;
            changelog.LoadChangelog();
            wait_changelog();
            assert(!changelog.Snapshot().changelog.operation_failed);
            assert(changelog.Snapshot().changelog.entries[0].comment == "7");
            assert(changelog.IssueURL(changelog.Snapshot().changelog.entries[0]) == "https://example.invalid/issues/42");
            assert(!changelog.IssueURL({1, "No issue", std::nullopt}));
            changelog.LoadChangelog();
            wait_changelog();
            assert(changelog_remote->changelog_requests == 3); // Reopening refetches successful content.
            assert(changelog_remote->requests == 0); // Never requests the latest release for a changelog.

            auto blocked_changelog = std::make_shared<BlockingState>();
            {
                VersionObservable pending(std::make_unique<VersionChecker>("1.0.0.7",
                    std::make_unique<GitHubReleaseStrategy>(std::make_unique<BlockingHttp>(blocked_changelog),
                        "https://example.invalid/releases/latest", [](const std::string &) {
                            return "https://example.invalid/changelog";
                        }), "", 60, std::nullopt, std::nullopt, [](auto, auto) {}), "1.0.0.7", "7", github_constants
                );
                pending.LoadChangelog();
                std::unique_lock lock(blocked_changelog->mutex);
                assert(blocked_changelog->changed.wait_for(lock, std::chrono::seconds(2), [&] {
                    return blocked_changelog->entered;
                }));
            }
            assert(blocked_changelog->canceled);

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
        const auto resource = sample.ToJson().Encode();
        CreditsObservable windows_credits(resource, std::make_unique<FakeHttp>(), Models::Platform::windows);
        CreditsObservable unix_credits(resource, std::make_unique<FakeHttp>(), Models::Platform::unixLike);
        assert(!windows_credits.HasLoadError() && !unix_credits.HasLoadError());
        assert(windows_credits.Snapshot().licenses.size() == 2);
        assert(windows_credits.Snapshot().licenses[0].name == "Common");
        assert(windows_credits.Snapshot().licenses[1].name == "Windows");
        assert(unix_credits.Snapshot().licenses.size() == 2);
        assert(unix_credits.Snapshot().licenses[0].name == "Common");
        assert(unix_credits.Snapshot().licenses[1].name == "Unix");
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

        DiagnosticsObservable diagnostics("test@example.invalid", {"Test App", "0.1.0", 4199}, "app.log", [&](const std::string &recipient, const Models::Issue &report) {
            assert(recipient == "test@example.invalid");
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
        assert(!diagnostics.Report("Unicode: café 日本語 $osLine"));
    } catch (const std::exception &error) {
        std::cerr << error.what() << std::endl;
        std::filesystem::remove_all(directory);
        return 1;
    }
    std::filesystem::remove_all(directory);
    std::cout << "Preferences, configuration, versions, cancellation and report preparation passed.\n";
}
