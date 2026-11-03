// SPDX-License-Identifier: GPL-3.0
#pragma once
#include "../business/tunnel.h"
#include "AppProfileHeader.h"
#include <condition_variable>
#include <deque>
#include <mutex>
#include <thread>

namespace Passepartout {
struct AppSnapshot {
    std::vector<Models::AppProfileHeader> profiles;
    std::vector<Models::AppTunnelInfo> tunnels;
    bool loaded = false;
    bool busy = true;
    bool tunnelAvailable = false;
    std::string error;
    std::uint64_t revision = 0;
};

// Shared serial executor for profile/tunnel transactions. Snapshots are copied
// under a lock; UI consumers never retain references into worker-owned models.
class AppSession {
public:
    AppSession(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
               std::unique_ptr<TunnelStrategy> tunnel);
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
    bool Post(std::function<void()> operation);
    void Run();
    void Publish();
    ProfileManager profiles_;
    TunnelManager tunnel_;
    mutable std::mutex mutex_;
    std::condition_variable wake_;
    std::deque<std::function<void()>> operations_;
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
    explicit TunnelObservable(AppSession &session) : session_(session) {}
    void Connect(std::string id);
    void Disconnect(std::string id);
    void Refresh();
    AppSnapshot Snapshot() const;
private:
    AppSession &session_;
};
}
