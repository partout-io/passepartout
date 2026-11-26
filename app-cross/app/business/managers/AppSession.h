// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../models/AppSnapshot.h"
#include "ProfileManager.h"
#include <partout/tunnel/Tunnel.h>
#include "../../context/AppLogger.h"
#include "AppPreferences.h"
#include "../models/ConfigurationFiles.h"
#include <condition_variable>
#include <deque>
#include <mutex>
#include <thread>

namespace Passepartout {
// Shared serial executor for profile/tunnel transactions. Snapshots are copied
// under a lock; UI consumers never retain references into worker-owned models.
class AppSession final {
public:
    AppSession(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
               std::unique_ptr<Partout::Tunnel> tunnel,
               std::shared_ptr<AppLogger> logger = std::make_shared<AppLogger>(),
               std::unique_ptr<ProfileJournal> journal = std::make_unique<MemoryProfileJournal>(),
               std::chrono::milliseconds recovery_delay = std::chrono::seconds(1),
               std::function<void(const Models::AppPreferences &)> apply_preferences = {}
    );
    ~AppSession();
    AppSession(const AppSession &) = delete;
    AppSession &operator=(const AppSession &) = delete;
    AppSnapshot Snapshot() const;
    std::optional<Profile> FindProfile(const std::string &id) const;
    // Returns whether the operation was queued; completion runs on the worker.
    bool SaveProfile(Profile original, Profile draft, std::function<void(bool)> completion);
    void Load();
    void Import(std::vector<std::filesystem::path> paths);
    void ImportFiles(std::shared_ptr<const ConfigurationFiles> files);
    void ImportFailed();
    void Remove(std::vector<std::string> ids);
    void Connect(std::string id, std::optional<Partout::Models::OpenVpnCredentials> credentials = {},
                 std::optional<Profile> original = {});
    void Disconnect(std::string id);
    void Refresh();
    void ClearError();
    void ApplyPreferences(Models::AppPreferences preferences);
    bool WaitIdle(std::chrono::milliseconds timeout);
private:
    bool Post(std::function<void()> operation, AppErrorContext context = AppErrorContext::general,
              bool foreground = true);
    void Run();
    void Publish();
    void ValidateNewRegistration(const std::string &id);
    void ValidateProfileUpdate(const std::string &id);
    void RollbackRegistration(const std::string &id);
    std::string RecoverProfiles();
    struct RecoveryRetry {
        unsigned attempts = 0;
        std::chrono::steady_clock::time_point next;
        std::string error;
    };
    std::map<std::string, RecoveryRetry> recovery_retries_;
    std::chrono::milliseconds recovery_delay_;
    std::shared_ptr<AppLogger> logger_;
    std::string last_observation_error_;
    std::string last_reconciliation_error_;
    bool register_missing_profiles_ = false;
    std::optional<Models::AppPreferences> pending_preferences_;
    ProfileManager profiles_;
    std::unique_ptr<Partout::Tunnel> tunnel_;
    std::optional<std::string> pending_profile_;
    std::function<void(const Models::AppPreferences &)> apply_preferences_;
    mutable std::mutex mutex_;
    std::condition_variable wake_;
    struct Operation {
        std::function<void()> run;
        AppErrorContext context;
        bool foreground;
    };
    std::deque<Operation> operations_;
    AppSnapshot snapshot_;
    std::vector<Profile> published_profiles_;
    std::shared_ptr<const ConfigurationFiles> importing_files_;
    bool stopping_ = false;
    std::thread worker_;
};
}
