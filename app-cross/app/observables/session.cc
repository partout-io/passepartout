// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "session.h"
#include <stdexcept>
#include <algorithm>
#include <type_traits>

namespace Passepartout {
AppSession::AppSession(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
                       std::unique_ptr<TunnelStrategy> tunnel)
    : profiles_(std::move(repository), std::move(importer)), tunnel_(std::move(tunnel)) {
    snapshot_.busy = false;
    worker_ = std::thread([this] {
        Run();
    });
    Load();
}
AppSession::~AppSession() {
    {
        std::lock_guard lock(mutex_);
        stopping_ = true;
        operations_.clear();
    }
    wake_.notify_all();
    worker_.join();
}
AppSnapshot AppSession::Snapshot() const {
    std::lock_guard lock(mutex_);
    return snapshot_;
}
bool AppSession::Post(std::function<void()> operation) {
    {
        std::lock_guard lock(mutex_);
        if (stopping_) return false;
        snapshot_.busy = true;
        snapshot_.error.clear();
        ++snapshot_.revision;
        operations_.push_back(std::move(operation));
    }
    wake_.notify_all();
    return true;
}
void AppSession::Run() {
    for (;;) {
        std::function<void()> operation;
        {
            std::unique_lock lock(mutex_);
            wake_.wait(lock, [&] {
                return stopping_ || !operations_.empty();
            });
            if (stopping_) return;
            operation = std::move(operations_.front());
            operations_.pop_front();
        }
        std::string error;
        try {
            operation();
        } catch (const std::exception &e) {
            error = e.what();
        } catch (...) {
            error = "The operation failed.";
        }
        // Refresh even after partial deletion or a failed connection. Never
        // publish a successful state merely because a request was accepted.
        try {
            Publish();
        } catch (const std::exception &e) {
            if (error.empty()) error = e.what();
        } catch (...) {
            if (error.empty()) error = "Unable to read VPN state.";
        }
        {
            std::lock_guard lock(mutex_);
            snapshot_.error = std::move(error);
            snapshot_.busy = !operations_.empty();
            ++snapshot_.revision;
        }
        wake_.notify_all();
    }
}
void AppSession::Publish() {
    std::vector<Models::AppProfileHeader> headers;
    for (const auto &profile : profiles_.Profiles()) {
        Models::AppProfileHeader header{};
        header.id = profile.id;
        header.name = profile.name;
        header.fingerprint = profile.id;
        if (profile.userInfo && profile.userInfo->is_object()) {
            const auto fingerprint = profile.userInfo->find("fingerprint");
            if (fingerprint != profile.userInfo->end() && fingerprint->is_string())
                header.fingerprint = fingerprint->get<std::string>();
        }
        for (const auto &module : profile.modules) {
            std::visit([&](const auto &value) {
                Partout::Models::ModuleType type;
                std::string id;
                if constexpr (std::is_same_v<std::decay_t<decltype(value)>, Partout::Models::TaggedModuleCustom>) {
                    type = value.value.innerType;
                    if (value.value.json.is_object()) {
                        const auto field = value.value.json.find("id");
                        if (field != value.value.json.end() && field->is_string()) id = field->template get<std::string>();
                    }
                } else {
                    type = Partout::Models::ModuleType::FromJson(value.type);
                    id = value.value.id;
                }
                header.moduleTypes.push_back(type);
                if (!header.primaryModuleType && !id.empty() &&
                    std::find(profile.activeModulesIds.begin(), profile.activeModulesIds.end(), id)
                        != profile.activeModulesIds.end()) header.primaryModuleType = type;
            }, module);
        }
        if (!header.primaryModuleType && !header.moduleTypes.empty())
            header.primaryModuleType = header.moduleTypes.front();
        for (const auto &type : header.moduleTypes) {
            if (!header.primaryModuleType || type != *header.primaryModuleType)
                header.secondaryModuleTypes.push_back(type);
        }
        headers.push_back(std::move(header));
    }
    {
        std::lock_guard lock(mutex_);
        snapshot_.profiles = std::move(headers);
        snapshot_.tunnelAvailable = false;
    }
    auto tunnels = tunnel_.Fetch();
    std::lock_guard lock(mutex_);
    snapshot_.tunnels = std::move(tunnels);
    snapshot_.tunnelAvailable = true;
}
void AppSession::Load() {
    Post([this] {
        profiles_.Load();
        std::lock_guard lock(mutex_);
        snapshot_.loaded = true;
    });
}
void AppSession::Import(std::vector<std::filesystem::path> paths) {
    Post([this, paths = std::move(paths)] {
        // Process every supplied activation, even if one configuration fails.
        std::size_t failures = 0;
        for (const auto &path : paths) {
            try {
                profiles_.Import(path);
            } catch (...) {
                ++failures;
            }
        }
        if (failures) throw std::runtime_error(std::to_string(failures) +
            " configuration(s) could not be imported. Valid imports were saved; existing profiles were preserved.");
    });
}
void AppSession::Remove(std::vector<std::string> ids) {
    Post([this, ids = std::move(ids)] {
        for (const auto &id : ids) {
            profiles_.Find(id);
            tunnel_.Remove(id);
            profiles_.Remove(id);
        }
    });
}
void AppSession::Connect(std::string id) {
    Post([this, id = std::move(id)] {
        tunnel_.Connect(profiles_.Find(id));
    });
}
void AppSession::Disconnect(std::string id) {
    Post([this, id = std::move(id)] {
        tunnel_.Disconnect(id);
    });
}
void AppSession::Refresh() {
    // Keep an actionable error visible until acknowledged or a user action.
    const auto state = Snapshot();
    if (state.busy || !state.error.empty()) return;
    Post([] {});
}
void AppSession::ClearError() {
    std::lock_guard lock(mutex_);
    snapshot_.error.clear();
    ++snapshot_.revision;
}
bool AppSession::WaitIdle(std::chrono::milliseconds timeout) {
    std::unique_lock lock(mutex_);
    return wake_.wait_for(lock, timeout, [&] {
        return !snapshot_.busy;
    });
}
void ProfileObservable::Load() {
    session_.Load();
}
void ProfileObservable::Import(std::vector<std::filesystem::path> paths) {
    session_.Import(std::move(paths));
}
void ProfileObservable::Remove(std::vector<std::string> ids) {
    session_.Remove(std::move(ids));
}
AppSnapshot ProfileObservable::Snapshot() const {
    return session_.Snapshot();
}
void ProfileObservable::ClearError() {
    session_.ClearError();
}
void TunnelObservable::Connect(std::string id) {
    session_.Connect(std::move(id));
}
void TunnelObservable::Disconnect(std::string id) {
    session_.Disconnect(std::move(id));
}
void TunnelObservable::Refresh() {
    session_.Refresh();
}
AppSnapshot TunnelObservable::Snapshot() const {
    return session_.Snapshot();
}
}
