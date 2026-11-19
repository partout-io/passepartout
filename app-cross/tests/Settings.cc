// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "business/strategy/FilePreferencesRepository.h"
#include "business/managers/ConfigManager.h"
#include "business/managers/VersionChecker.h"
#include "business/managers/IssueReporter.h"
#include "business/extensions/AppLogger.h"
#include "business/models/Profile.h"
#include "observables/UserPreferencesObservable.h"
#include "observables/ConfigObservable.h"
#include "observables/CreditsObservable.h"
#include "context/Dependencies.h"
#include "SettingsResources.h"
#include <cassert>
#include <fstream>
#include <iostream>
#include <condition_variable>
#include "Support.h"

using namespace Passepartout;
namespace {
class MemoryPreferences final : public PreferencesRepository {
public:
    Models::AppPreferences value = DefaultPreferences();
    bool fails = false;
    Models::AppPreferences Fetch() override {
        return value;
    }
    void Save(const Models::AppPreferences &next) override {
        if (fails) throw std::runtime_error("Save failed");
        value = next;
    }
};
class FakeHttp final : public HttpClient {
public:
    std::string response = "{}";
    bool fails = false;
    unsigned requests = 0;
    std::string Get(const std::string &) override {
        ++requests;
        if (fails) throw std::runtime_error("Offline");
        return response;
    }
    void Cancel() noexcept override {}
};
class FakeVersion final : public VersionStrategy {
public:
    std::string value = "1.2.3.4";
    bool fails = false;
    unsigned requests = 0;
    std::string LatestVersion() override {
        ++requests;
        if (fails) throw std::runtime_error("Offline");
        return value;
    }
    void Cancel() noexcept override {}
};
struct BlockingState {
    std::mutex mutex;
    std::condition_variable changed;
    bool entered = false;
    bool canceled = false;
};
class BlockingHttp final : public HttpClient {
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
int main() {
    InitializeTests();
    const auto directory = std::filesystem::temp_directory_path() /
        ("passepartout-settings-test-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directory(directory);
    try {
        FilePreferencesRepository repository(directory / "preferences.json");
        auto persisted = repository.Fetch();
        assert(persisted.dnsFallsBack && !persisted.logsPrivateData);
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

        auto http = std::make_unique<FakeHttp>();
        auto *remote = http.get();
        remote->response = R"({"futureFlag": {}, "appNotWorking": {"rate":100,"minBuild":7,"platforms":["windows"],"data":{"reason":"test"}}})";
        ConfigManager config(std::move(http), "https://example.invalid", 7, std::chrono::seconds(0));
        assert(config.Refresh());
        assert(config.ActiveFlags().at(Models::ConfigFlag::appNotWorking).at("reason") == "test");
        remote->fails = true;
        Fails([&] { config.Refresh(); });
        assert(config.ActiveFlags().size() == 1);
        remote->fails = false;
        for (const auto &value : {R"({"rate":99})", R"({"rate":100,"minBuild":8})", R"({"rate":100,"platforms":["android"]})"}) {
            remote->response = std::string("{\"appNotWorking\":") + value + "}";
            assert(config.Refresh() && config.ActiveFlags().empty());
        }
        auto throttledHttp = std::make_unique<FakeHttp>();
        auto *throttledRemote = throttledHttp.get();
        ConfigManager throttled(std::move(throttledHttp), "https://example.invalid", 7, std::chrono::hours(1));
        assert(throttled.Refresh() && !throttled.Refresh() && throttledRemote->requests == 1);
        auto blocked = std::make_shared<BlockingState>();
        {
            ConfigObservable observable(std::make_unique<ConfigManager>(std::make_unique<BlockingHttp>(blocked),
                "https://example.invalid", 7, std::chrono::hours(1)));
            observable.Refresh();
            std::unique_lock lock(blocked->mutex);
            assert(blocked->changed.wait_for(lock, std::chrono::seconds(2), [&] { return blocked->entered; }));
        }
        assert(blocked->canceled); // Destruction cancels before joining the blocked worker.

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

        CreditsObservable credits(creditsResource, std::make_unique<FakeHttp>());
        assert(!credits.HasLoadError() && credits.Snapshot().licenses.size() >= 10);
        for (const auto &license : credits.Snapshot().licenses) assert(license.name != "OpenSSL" && license.name != "Wintun");
        AppLogger logger;
        AppLogger::SetPrivateData(false);
        logger.Write(LogLevel::info, "test", "public marker");
        AppLogger::SetPrivateData(true);
        logger.Write(LogLevel::info, "test", "private marker");
        AppLogger::SetPrivateData(false);
        assert(AppLogger::RuntimeLog().find("private marker") != std::string::npos);
        assert(AppLogger::RuntimeLog(false).find("private marker") == std::string::npos);
        std::filesystem::path attachment;
        IssueReporter reporter("test@example.invalid", "0.1.0.7", [&](const IssueReport &report) {
            assert(report.comment == "Unicode: café 日本語" && report.attachments.size() == 2);
            attachment = report.attachments.back();
            assert(ReadConfiguration(attachment).find("public marker") != std::string::npos);
            assert(ReadConfiguration(attachment).find("private marker") == std::string::npos);
            return false; // No mail provider; preparation still cleans up.
        });
        assert(!reporter.Report("Unicode: café 日本語", AppLogger::RuntimeLog(false)));
        assert(!std::filesystem::exists(attachment.parent_path()));
    } catch (const std::exception &error) {
        std::cerr << error.what() << std::endl;
        std::filesystem::remove_all(directory);
        return 1;
    }
    std::filesystem::remove_all(directory);
    std::cout << "Preferences, configuration, versions, cancellation and report preparation passed.\n";
}
