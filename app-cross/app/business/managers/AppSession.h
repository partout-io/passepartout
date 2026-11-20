// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../models/AppSnapshot.h"
#include "../models/ProfileEditor.h"
#include "ProfileManager.h"
#include "TunnelManager.h"
#include "../models/ConfigurationFiles.h"
#include <condition_variable>
#include <deque>
#include <mutex>
#include <thread>

namespace Passepartout {
// Shared serial executor for profile/tunnel transactions. Snapshots are copied
// under a lock; UI consumers never retain references into worker-owned models.
class AppSession {
public:
    AppSession(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
               std::unique_ptr<TunnelStrategy> tunnel,
               std::shared_ptr<AppLogger> logger = std::make_shared<AppLogger>(),
               std::unique_ptr<ProfileJournal> journal = std::make_unique<MemoryProfileJournal>(),
               std::chrono::milliseconds recoveryDelay = std::chrono::seconds(1));
    ~AppSession();
    AppSession(const AppSession &) = delete;
    AppSession &operator=(const AppSession &) = delete;
    AppSnapshot Snapshot() const;
    std::shared_ptr<ProfileEditor> CreateEditor(const std::string &id) const;
    void SaveEditor(std::shared_ptr<ProfileEditor> editor);
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
    std::string RecoverProfiles();
    struct RecoveryRetry {
        unsigned attempts = 0;
        std::chrono::steady_clock::time_point next;
        std::string error;
    };
    std::map<std::string, RecoveryRetry> recoveryRetries_;
    std::chrono::milliseconds recoveryDelay_;
    std::shared_ptr<AppLogger> logger_;
    std::string lastObservationError_;
    std::string lastReconciliationError_;
    bool registerMissingProfiles_ = false;
    std::optional<Models::AppPreferences> pendingPreferences_;
    ProfileManager profiles_;
    TunnelManager tunnel_;
    mutable std::mutex mutex_;
    std::condition_variable wake_;
    struct Operation {
        std::function<void()> run;
        AppErrorContext context;
        bool foreground;
    };
    std::deque<Operation> operations_;
    AppSnapshot snapshot_;
    std::vector<Profile> editableProfiles_;
    std::shared_ptr<const ConfigurationFiles> importingFiles_;
    bool stopping_ = false;
    std::thread worker_;
};
}
