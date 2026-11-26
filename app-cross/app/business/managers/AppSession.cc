// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../models/FileConfigurationFiles.h"
#include "AppSession.h"
#include <stdexcept>
#include <algorithm>
#include <type_traits>
#include <set>

namespace Passepartout {
AppSession::AppSession(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
                       std::unique_ptr<Partout::Tunnel> tunnel, std::shared_ptr<AppLogger> logger,
                       std::function<void(const Models::AppPreferences &)> apply_preferences
)
    : logger_(std::move(logger)), profiles_(std::move(repository), std::move(importer)),
      tunnel_(std::move(tunnel)), apply_preferences_(std::move(apply_preferences)) {
    logger_->Write(LogLevel::info, LogCategory::core, "Start application session");
    snapshot_.busy = false;
    worker_ = std::thread([this] {
        Run();
    });
    Load();
}

AppSession::~AppSession() {
    std::shared_ptr<const ConfigurationFiles> importing;
    {
        std::lock_guard lock(mutex_);
        stopping_ = true;
        operations_.clear();
        importing = importing_files_;
    }
    if (importing) importing->Cancel();
    wake_.notify_all();
    tunnel_->Cancel();
    worker_.join();
    logger_->Write(LogLevel::info, LogCategory::core, "Finished application session");
}

AppSnapshot AppSession::Snapshot() const {
    std::lock_guard lock(mutex_);
    return snapshot_;
}

void AppSession::ApplyPreferences(Models::AppPreferences preferences) {
    Post([this, preferences = std::move(preferences)] {
        pending_preferences_ = preferences;
        if (apply_preferences_) apply_preferences_(*pending_preferences_);
        pending_preferences_.reset();
    }, AppErrorContext::tunnel);
}

bool AppSession::Post(std::function<void()> operation, AppErrorContext context, bool foreground) {
    {
        std::lock_guard lock(mutex_);
        if (stopping_) return false;
        snapshot_.busy = true;
        snapshot_.foreground_busy = snapshot_.foreground_busy || foreground;
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
            try {
                tunnel_->Advance();
            } catch (...) {
                pending_profile_.reset();
                operation.context = AppErrorContext::tunnel;
                throw;
            }
        } catch (const std::exception &e) {
            error = e.what();
        } catch (...) {
            error = "The operation failed.";
        }
        if (!error.empty()) logger_->Write(LogLevel::error, LogCategory::core, "Unable to execute operation");
        // A failed state refresh must not turn a committed import into a
        // failed import. Keep operation and observation failures separate.
        std::string tunnel_error;
        try {
            Publish();
        } catch (const std::exception &e) {
            tunnel_error = e.what();
        } catch (...) {
            tunnel_error = "Unable to read VPN state.";
        }
        if (tunnel_error != last_observation_error_) {
            logger_->Write(tunnel_error.empty() ? LogLevel::info : LogLevel::error, LogCategory::tunnel,
                tunnel_error.empty() ? "Tunnel observation recovered" : "Unable to fetch tunnel state");
            last_observation_error_ = tunnel_error;
        }
        {
            std::lock_guard lock(mutex_);
            if (!tunnel_error.empty()) snapshot_.tunnel_available = false;
            snapshot_.pending_profile = pending_profile_;
            snapshot_.error = std::move(error);
            snapshot_.tunnel_error = std::move(tunnel_error);
            snapshot_.error_context = operation.context;
            snapshot_.busy = !operations_.empty();
            snapshot_.foreground_busy = std::any_of(operations_.begin(), operations_.end(), [](const auto &queued) {
                return queued.foreground;
            });
            ++snapshot_.revision;
        }
        wake_.notify_all();
    }
}

std::string AppSession::SynchronizeProfiles(const std::vector<Models::AppTunnelInfo> &tunnels) {
    if (!Snapshot().loaded) return {};
    const auto unavailable = tunnel_->ObservationErrors();
    std::string error;
    for (const auto &profile : profiles_.Profiles()) {
        if (unavailable.count(profile.id)) continue;
        const auto native = std::find_if(tunnels.begin(), tunnels.end(), [&](const auto &value) {
            return value.id == profile.id;
        });
        // Preserve a running connection; apply saved edits after it disconnects.
        if (native != tunnels.end() && (native->isEnabled || native->status.value != Status::disconnected)) continue;
        const auto synchronized = synchronized_profiles_.find(profile.id);
        if (native != tunnels.end() && synchronized != synchronized_profiles_.end() && synchronized->second == profile) continue;
        try {
            tunnel_->Save(profile);
            synchronized_profiles_[profile.id] = profile;
        } catch (...) {
            error = "Unable to synchronize saved VPN profile " + profile.id + ".";
        }
    }
    // Fetch exposes only this app's registrations. Never clean up after a failed local load.
    for (const auto &native : tunnels) {
        if (unavailable.count(native.id)) continue;
        const bool exists = std::any_of(profiles_.Profiles().begin(), profiles_.Profiles().end(), [&](const auto &profile) {
            return profile.id == native.id;
        });
        if (exists) continue;
        try {
            tunnel_->Remove(native.id);
            synchronized_profiles_.erase(native.id);
        } catch (...) {
            error = "Unable to remove VPN registration " + native.id + ".";
        }
    }
    return error;
}

void AppSession::Publish() {
    std::vector<Models::AppProfileHeader> headers;
    for (const auto &profile : profiles_.Profiles()) {
        Models::AppProfileHeader header{};
        header.id = profile.id;
        header.name = profile.name;
        header.fingerprint = profile.id;
        if (profile.userInfo && profile.userInfo->IsObject()) {
            const auto fingerprint = profile.userInfo->Find("fingerprint");
            if (fingerprint && fingerprint->IsString())
                header.fingerprint = fingerprint->Get<std::string>();
        }
        for (const auto &module : profile.modules) {
            std::visit([&](const auto &value) {
                Partout::Models::ModuleType type;
                std::string id;
                if constexpr (std::is_same_v<std::decay_t<decltype(value)>, Partout::Models::TaggedModuleCustom>) {
                    type = value.value.innerType;
                    if (value.value.json.IsObject()) {
                        const auto field = value.value.json.Find("id");
                        if (field && field->IsString()) id = field->template Get<std::string>();
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
        published_profiles_ = profiles_.Profiles();
    }
    auto tunnels = Tunnels::Info(tunnel_->Fetch());
    auto synchronization_error = SynchronizeProfiles(tunnels);
    tunnels = Tunnels::Info(tunnel_->Fetch());
    if (synchronization_error != last_synchronization_error_) {
        logger_->Write(synchronization_error.empty() ? LogLevel::info : LogLevel::error, LogCategory::profiles,
            synchronization_error.empty() ? "Profile synchronization succeeded" : synchronization_error);
        last_synchronization_error_ = synchronization_error;
    }
    const auto previous = Snapshot();
    const auto observation_errors = tunnel_->ObservationErrors();
    for (const auto &[id, error] : observation_errors) {
        const auto old = previous.tunnel_observation_errors.find(id);
        if (old == previous.tunnel_observation_errors.end() || old->second != error)
            logger_->Write(LogLevel::error, LogCategory::tunnel, "Unable to observe profile " + id + ": " + error);
    }
    for (const auto &[id, error] : previous.tunnel_observation_errors) {
        if (observation_errors.find(id) == observation_errors.end())
            logger_->Write(LogLevel::info, LogCategory::tunnel, "Profile observation error cleared: " + id);
    }
    for (const auto &tunnel : tunnels) {
        const auto old = std::find_if(previous.tunnels.begin(), previous.tunnels.end(), [&](const auto &value) {
            return value.id == tunnel.id;
        });
        if (old == previous.tunnels.end() || old->status != tunnel.status)
            logger_->Write(LogLevel::info, LogCategory::tunnel, "Profile " + tunnel.id + " status: " + tunnel.status.ToJson().Encode());
    }
    // The requested target is presentation state; Partout owns the handover.
    if (pending_profile_ && std::any_of(tunnels.begin(), tunnels.end(), [&](const auto &tunnel) {
        return tunnel.id == *pending_profile_ && tunnel.status.value == Status::connected;
    })) pending_profile_.reset();
    std::lock_guard lock(mutex_);
    snapshot_.tunnels = std::move(tunnels);
    snapshot_.tunnel_available = true;
    snapshot_.tunnel_observation_errors = observation_errors;
    snapshot_.synchronization_error = std::move(synchronization_error);
}

void AppSession::Load() {
    Post([this] {
        {
            std::lock_guard lock(mutex_);
            snapshot_.loaded = false;
        }
        logger_->Write(LogLevel::info, LogCategory::profiles, "Reload local profiles...");
        profiles_.Load();
        logger_->Write(LogLevel::info, LogCategory::profiles, "Reloaded local profiles: " + std::to_string(profiles_.Profiles().size()));
        {
            std::lock_guard lock(mutex_);
            snapshot_.loaded = true;
        }
        synchronized_profiles_.clear();
    });
}

std::optional<Profile> AppSession::FindProfile(const std::string &id) const {
    std::lock_guard lock(mutex_);
    if (!snapshot_.loaded || snapshot_.foreground_busy) return {};
    for (const auto &profile : published_profiles_) {
        if (profile.id == id) return profile;
    }
    return {};
}

bool AppSession::SaveProfile(Profile original, Profile draft, std::function<void(bool)> completion) {
    return Post([this, original = std::move(original), draft = std::move(draft), completion = std::move(completion)] {
        bool succeeded = false;
        try {
            profiles_.Update(original, draft);
            succeeded = true;
        } catch (...) {
            // The editor reports storage failures and retains its draft.
        }
        completion(succeeded);
    });
}

void AppSession::Import(std::vector<std::filesystem::path> paths) {
    ImportFiles(std::make_shared<FileConfigurationFiles>(std::move(paths)));
}

void AppSession::ImportFiles(std::shared_ptr<const ConfigurationFiles> files) {
    if (!files || (!files->Count() && !files->SelectionFailures())) return;
    Post([this, files = std::move(files)] {
        {
            std::lock_guard lock(mutex_);
            if (stopping_) return;
            importing_files_ = files;
        }
        struct ReleaseFiles {
            AppSession &session;
            ~ReleaseFiles() {
                std::lock_guard lock(session.mutex_);
                session.importing_files_.reset();
            }
        } release{*this};
        // Process every supplied activation, even if one configuration fails.
        std::size_t failures = files->SelectionFailures();
        for (std::size_t index = 0; index < files->Count(); ++index) {
            {
                std::lock_guard lock(mutex_);
                if (stopping_) return;
            }
            try {
                logger_->Write(LogLevel::info, LogCategory::profiles, "Import profile...");
                const auto source = files->Read(index);
                profiles_.ImportText(source.text, source.name);
                logger_->Write(LogLevel::info, LogCategory::profiles, "Finished saving profile");
            } catch (const std::exception &) {
                logger_->Write(LogLevel::error, LogCategory::profiles, "Unable to import profile");
                ++failures;
            } catch (...) {
                ++failures;
            }
        }
        if (failures) throw std::runtime_error(std::to_string(failures) +
            " configuration(s) could not be imported. Valid imports were saved; existing profiles were preserved.");
    }, AppErrorContext::import);
}

void AppSession::ImportFailed() {
    Post([] {
        throw std::runtime_error("Configuration selection failed.");
    }, AppErrorContext::import);
}

void AppSession::Remove(std::vector<std::string> ids) {
    Post([this, ids = std::move(ids)] {
        const std::set<std::string> unique_ids(ids.begin(), ids.end());
        // A menu or confirmation can outlive its targets. Validate the entire
        // request before deleting anything, on the same worker as mutations.
        for (const auto &id : unique_ids) profiles_.Find(id);
        for (const auto &id : unique_ids) {
            logger_->Write(LogLevel::info, LogCategory::profiles, "Remove profile");
            profiles_.Remove(id);
            if (pending_profile_ == id) {
                pending_profile_.reset();
            }
        }
    });
}

void AppSession::Connect(std::string id, std::optional<Partout::Models::OpenVpnCredentials> credentials,
    std::optional<Profile> original) {
    Post([this, id = std::move(id), credentials = std::move(credentials), original = std::move(original)] {
        if (pending_preferences_) {
            if (apply_preferences_) apply_preferences_(*pending_preferences_);
            pending_preferences_.reset();
        }
        const auto profile = profiles_.Find(id);
        if (original && profile != *original) throw std::runtime_error("Profile changed during interactive login.");
        std::optional<Partout::TunnelCredentials> authentication;
        if (credentials) authentication = Partout::TunnelCredentials{credentials->username, credentials->password};
        pending_profile_.reset();
        const auto native = tunnel_->Fetch();
        const bool already_active = std::any_of(native.begin(), native.end(), [&](const auto &value) {
            return value.id == id && value.status.value == Partout::Models::TunnelStatus::active;
        });
        const auto synchronized = synchronized_profiles_.find(id);
        const bool installed = std::any_of(native.begin(), native.end(), [&](const auto &value) {
            return value.id == id;
        });
        if (!already_active && (!installed || synchronized == synchronized_profiles_.end() || synchronized->second != profile)) {
            // Never connect using an older native configuration after a synchronization failure.
            tunnel_->Save(profile);
            synchronized_profiles_[id] = profile;
        }
        tunnel_->Connect(profile, std::move(authentication));
        pending_profile_ = id;
    }, AppErrorContext::tunnel);
}

void AppSession::Disconnect(std::string id) {
    Post([this, id = std::move(id)] {
        pending_profile_.reset();
        tunnel_->Disconnect(id);
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
}
