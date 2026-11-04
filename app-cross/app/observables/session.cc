// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "session.h"
#include <stdexcept>
#include <algorithm>
#include <type_traits>

namespace Passepartout {
bool AppSnapshot::HasActivity() const {
    if (foregroundBusy || pendingProfile) return true;
    return tunnelAvailable && std::any_of(tunnels.begin(), tunnels.end(), [](const auto &tunnel) {
        return tunnel.status.value == Status::connecting || tunnel.status.value == Status::disconnecting;
    });
}

AppSession::AppSession(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
                       std::unique_ptr<TunnelStrategy> tunnel, std::shared_ptr<AppLogger> logger)
    : logger_(std::move(logger)), profiles_(std::move(repository), std::move(importer)),
      tunnel_(std::move(tunnel), logger_) {
    logger_->Write(LogLevel::info, "core", "Start application session");
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
    logger_->Write(LogLevel::info, "core", "Finished application session");
}
AppSnapshot AppSession::Snapshot() const {
    std::lock_guard lock(mutex_);
    return snapshot_;
}
bool AppSession::Post(std::function<void()> operation, AppErrorContext context, bool foreground) {
    {
        std::lock_guard lock(mutex_);
        if (stopping_) return false;
        snapshot_.busy = true;
        snapshot_.foregroundBusy = snapshot_.foregroundBusy || foreground;
        snapshot_.error.clear();
        ++snapshot_.revision;
        operations_.push_back({std::move(operation), context, foreground});
    }
    wake_.notify_all();
    return true;
}
void AppSession::Run() {
    for (;;) {
        Operation operation;
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
            operation.run();
            if (tunnel_.PendingProfile()) {
                operation.context = AppErrorContext::tunnel;
                tunnel_.Advance();
            }
        } catch (const std::exception &e) {
            error = e.what();
        } catch (...) {
            error = "The operation failed.";
        }
        if (!error.empty()) logger_->Write(LogLevel::error, "core", "Unable to execute operation: " + error);
        // A failed state refresh must not turn a committed import into a
        // failed import. Keep operation and observation failures separate.
        std::string tunnelError;
        try {
            Publish();
        } catch (const std::exception &e) {
            tunnelError = e.what();
        } catch (...) {
            tunnelError = "Unable to read VPN state.";
        }
        if (tunnelError != lastObservationError_) {
            logger_->Write(tunnelError.empty() ? LogLevel::info : LogLevel::error, "tunnel",
                tunnelError.empty() ? "Tunnel observation recovered" : "Unable to fetch tunnel state: " + tunnelError);
            lastObservationError_ = tunnelError;
        }
        {
            std::lock_guard lock(mutex_);
            if (!tunnelError.empty()) snapshot_.tunnelAvailable = false;
            snapshot_.pendingProfile = tunnel_.PendingProfile();
            snapshot_.error = std::move(error);
            snapshot_.tunnelError = std::move(tunnelError);
            snapshot_.errorContext = operation.context;
            snapshot_.busy = !operations_.empty();
            snapshot_.foregroundBusy = std::any_of(operations_.begin(), operations_.end(), [](const auto &queued) {
                return queued.foreground;
            });
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
    }
    auto tunnels = tunnel_.Fetch();
    std::string reconciliationError;
    if (registerMissingProfiles_) {
        const auto unavailable = tunnel_.ObservationErrors();
        try {
            for (const auto &profile : profiles_.Profiles()) {
                if (unavailable.find(profile.id) != unavailable.end()) continue;
                const bool exists = std::any_of(tunnels.begin(), tunnels.end(), [&](const auto &tunnel) {
                    return tunnel.id == profile.id;
                });
                if (!exists) tunnel_.Save(profile);
            }
            tunnels = tunnel_.Fetch();
            registerMissingProfiles_ = false;
        } catch (const std::exception &error) {
            reconciliationError = "Unable to register saved profiles: " + std::string(error.what());
        }
    }
    if (Snapshot().loaded && reconciliationError.empty()) {
        bool removed = false;
        for (const auto &tunnel : tunnels) {
            const auto &profiles = profiles_.Profiles();
            const bool exists = std::any_of(profiles.begin(), profiles.end(), [&](const auto &profile) {
                return profile.id == tunnel.id;
            });
            if (exists) continue;
            try {
                if (lastReconciliationError_.empty())
                    logger_->Write(LogLevel::info, "profiles", "Remove orphaned profile registration " + tunnel.id + "...");
                tunnel_.Remove(tunnel.id);
                removed = true;
            } catch (const std::exception &e) {
                reconciliationError = "Unable to remove orphaned profile " + tunnel.id + ": " + e.what();
                break;
            }
        }
        if (removed) tunnels = tunnel_.Fetch();
    }
    if (reconciliationError != lastReconciliationError_) {
        logger_->Write(reconciliationError.empty() ? LogLevel::info : LogLevel::error, "profiles",
            reconciliationError.empty() ? "Profile reconciliation recovered" : reconciliationError);
        lastReconciliationError_ = reconciliationError;
    }
    const auto previous = Snapshot();
    const auto observationErrors = tunnel_.ObservationErrors();
    for (const auto &[id, error] : observationErrors) {
        const auto old = previous.tunnelObservationErrors.find(id);
        if (old == previous.tunnelObservationErrors.end() || old->second != error)
            logger_->Write(LogLevel::error, "tunnel", "Unable to observe profile " + id + ": " + error);
    }
    for (const auto &[id, error] : previous.tunnelObservationErrors) {
        if (observationErrors.find(id) == observationErrors.end())
            logger_->Write(LogLevel::info, "tunnel", "Profile observation error cleared: " + id);
    }
    for (const auto &tunnel : tunnels) {
        const auto old = std::find_if(previous.tunnels.begin(), previous.tunnels.end(), [&](const auto &value) {
            return value.id == tunnel.id;
        });
        if (old == previous.tunnels.end() || old->status != tunnel.status)
            logger_->Write(LogLevel::info, "tunnel", "Profile " + tunnel.id + " status: " + tunnel.status.ToJson().dump());
    }
    std::lock_guard lock(mutex_);
    snapshot_.tunnels = std::move(tunnels);
    snapshot_.tunnelAvailable = true;
    snapshot_.tunnelObservationErrors = observationErrors;
    snapshot_.reconciliationError = std::move(reconciliationError);
}

void AppSession::Load() {
    Post([this] {
        logger_->Write(LogLevel::info, "profiles", "Reload local profiles...");
        profiles_.Load();
        logger_->Write(LogLevel::info, "profiles", "Reloaded local profiles: " + std::to_string(profiles_.Profiles().size()));
        {
            std::lock_guard lock(mutex_);
            snapshot_.loaded = true;
        }
        registerMissingProfiles_ = true;
    });
}
void AppSession::Import(std::vector<std::filesystem::path> paths) {
    Post([this, paths = std::move(paths)] {
        // Process every supplied activation, even if one configuration fails.
        std::size_t failures = 0;
        for (const auto &path : paths) {
            try {
                logger_->Write(LogLevel::info, "profiles", "Import profile...");
                const auto profile = profiles_.Import(path, [this](const Profile &value) {
                    tunnel_.Register(value);
                }, [this](const std::string &id) {
                    tunnel_.RollbackRegistration(id);
                });
                logger_->Write(LogLevel::info, "profiles", "Finished saving profile " + profile.id);
            } catch (const std::exception &error) {
                logger_->Write(LogLevel::error, "profiles", "Unable to import profile: " + std::string(error.what()));
                ++failures;
            } catch (...) {
                ++failures;
            }
        }
        if (failures) throw std::runtime_error(std::to_string(failures) +
            " configuration(s) could not be imported. Valid imports were saved; existing profiles were preserved.");
    }, AppErrorContext::import);
}
void AppSession::Remove(std::vector<std::string> ids) {
    Post([this, ids = std::move(ids)] {
        for (const auto &id : ids) {
            profiles_.Find(id);
            logger_->Write(LogLevel::info, "profiles", "Remove profile " + id + "...");
            profiles_.Remove(id);
            tunnel_.CancelPending(id);
        }
    });
}
void AppSession::Connect(std::string id) {
    Post([this, id = std::move(id)] {
        tunnel_.Connect(profiles_.Find(id));
    }, AppErrorContext::tunnel);
}
void AppSession::Disconnect(std::string id) {
    Post([this, id = std::move(id)] {
        tunnel_.Disconnect(id);
    }, AppErrorContext::tunnel);
}
void AppSession::Refresh() {
    // Keep an actionable error visible until acknowledged or a user action.
    const auto state = Snapshot();
    if (state.busy || !state.error.empty()) return;
    Post([] {}, AppErrorContext::general, false);
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
TunnelObservable::ToggleState TunnelObservable::StateForProfile(const AppSnapshot &state, const std::string &id) {
    ToggleState result;
    for (const auto &tunnel : state.tunnels) {
        if (tunnel.id == id) {
            result.isOn = tunnel.isEnabled;
            result.status = tunnel.status.value;
        }
    }
    const bool exists = std::any_of(state.profiles.begin(), state.profiles.end(), [&](const auto &profile) {
        return profile.id == id;
    });
    result.canInteract = exists && state.loaded && !state.foregroundBusy && !state.pendingProfile && state.tunnelAvailable &&
        state.tunnelObservationErrors.find(id) == state.tunnelObservationErrors.end() &&
        result.status != Status::disconnecting;
    return result;
}
void TunnelObservable::SetEnabled(const std::string &id, bool enabled) {
    const auto state = StateForProfile(Snapshot(), id);
    if (!state.canInteract || state.isOn == enabled) return;
    if (enabled) Connect(id);
    else Disconnect(id);
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
