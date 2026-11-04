// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/tunnel.h"
#include "AppProfileHeader.h"
#include <condition_variable>
#include <deque>
#include <mutex>
#include <thread>

namespace Passepartout {
enum class AppErrorContext { general, import, tunnel };

struct AppSnapshot {
    std::vector<Models::AppProfileHeader> profiles;
    std::vector<Models::AppTunnelInfo> tunnels;
    std::map<std::string, std::string> tunnelObservationErrors;
    bool loaded = false;
    bool busy = true;
    bool tunnelAvailable = false;
    bool foregroundBusy = false;
    std::optional<std::string> pendingProfile;
    bool HasActivity() const;
    std::string error;
    std::string tunnelError;
    std::string reconciliationError;
    AppErrorContext errorContext = AppErrorContext::general;
    std::uint64_t revision = 0;
};

// Shared serial executor for profile/tunnel transactions. Snapshots are copied
// under a lock; UI consumers never retain references into worker-owned models.
class AppSession {
public:
    AppSession(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
               std::unique_ptr<TunnelStrategy> tunnel,
               std::shared_ptr<AppLogger> logger = std::make_shared<AppLogger>());
    ~AppSession();
    AppSession(const AppSession &) = delete;
    AppSession &operator=(const AppSession &) = delete;
    AppSnapshot Snapshot() const;
    void Load();
    void Import(std::vector<std::filesystem::path> paths);
    void Remove(std::vector<std::string> ids);
    void Connect(std::string id);
    void Disconnect(std::string id);
    void Refresh();
    void ClearError();
    bool WaitIdle(std::chrono::milliseconds timeout);
private:
    bool Post(std::function<void()> operation, AppErrorContext context = AppErrorContext::general,
              bool foreground = true);
    void Run();
    void Publish();
    std::shared_ptr<AppLogger> logger_;
    std::string lastObservationError_;
    std::string lastReconciliationError_;
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
    bool stopping_ = false;
    std::thread worker_;
};

class ProfileObservable {
public:
    explicit ProfileObservable(AppSession &session) : session_(session) {}
    void Load();
    void Import(std::vector<std::filesystem::path> paths);
    void Remove(std::vector<std::string> ids);
    AppSnapshot Snapshot() const;
    void ClearError();
private:
    AppSession &session_;
};
class TunnelObservable {
public:
    struct ToggleState {
        bool isOn = false;
        bool canInteract = false;
        Status status = Status::disconnected;
    };
    explicit TunnelObservable(AppSession &session) : session_(session) {}
    static ToggleState StateForProfile(const AppSnapshot &state, const std::string &id);
    void SetEnabled(const std::string &id, bool enabled);
    void Connect(std::string id);
    void Disconnect(std::string id);
    void Refresh();
    AppSnapshot Snapshot() const;
private:
    AppSession &session_;
};
}
