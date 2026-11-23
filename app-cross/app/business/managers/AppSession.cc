// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AppSession.h"
#include <stdexcept>
#include <algorithm>
#include <type_traits>
#include <set>

namespace Passepartout {
AppSession::AppSession(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
                       std::unique_ptr<Partout::Tunnel> tunnel, std::shared_ptr<AppLogger> logger,
                       std::unique_ptr<ProfileJournal> journal, std::chrono::milliseconds recovery_delay,
                       std::function<void(const Models::AppPreferences &)> apply_preferences
)
    : recovery_delay_(recovery_delay), logger_(std::move(logger)), profiles_(std::move(repository), std::move(importer), std::move(journal)),
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
            if (tunnel_->PendingProfile()) {
                operation.context = AppErrorContext::tunnel;
                tunnel_->Advance();
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
            snapshot_.pending_profile = tunnel_->PendingProfile();
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
std::string AppSession::RecoverProfiles() {
    std::string error;
    for (const auto &transaction : profiles_.PendingTransactions()) {
        auto &retry = recovery_retries_[transaction.id];
        if (std::chrono::steady_clock::now() < retry.next) {
            error = retry.error;
            continue;
        }
        try {
            profiles_.Recover(transaction, [this](const ProfileTransaction &pending) {
                if (pending.removal) tunnel_->Remove(pending.id);
                else if (pending.previous) {
                    tunnel_->ValidateUpdate(*pending.previous);
                    tunnel_->Save(*pending.previous);
                } else tunnel_->RollbackRegistration(pending.id);
            });
            recovery_retries_.erase(transaction.id);
        } catch (...) {
            retry.attempts = std::min(retry.attempts + 1, 5u);
            retry.next = std::chrono::steady_clock::now() + recovery_delay_ * (1u << retry.attempts);
            retry.error = "Unable to recover profile " + transaction.id + ". Recovery will be retried.";
            error = retry.error;
        }
    }
    std::vector<std::string> pending_ids;
    for (const auto &transaction : profiles_.PendingTransactions()) pending_ids.push_back(transaction.id);
    std::lock_guard lock(mutex_);
    snapshot_.recovering_profiles = std::move(pending_ids);
    return error;
}
void AppSession::Publish() {
    std::string reconciliation_error;
    if (Snapshot().loaded) reconciliation_error = RecoverProfiles();
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
        editable_profiles_ = profiles_.Profiles();
    }
    auto tunnels = Tunnels::Info(tunnel_->Fetch());
    if (register_missing_profiles_) {
        const auto unavailable = tunnel_->ObservationErrors();
        try {
            for (const auto &profile : profiles_.Profiles()) {
                if (unavailable.find(profile.id) != unavailable.end()) continue;
                const auto state = Snapshot();
                if (std::find(state.recovering_profiles.begin(), state.recovering_profiles.end(), profile.id)
                    != state.recovering_profiles.end()) continue;
                const bool exists = std::any_of(tunnels.begin(), tunnels.end(), [&](const auto &tunnel) {
                    return tunnel.id == profile.id;
                });
                if (!exists) tunnel_->Save(profile);
            }
            tunnels = Tunnels::Info(tunnel_->Fetch());
            register_missing_profiles_ = false;
        } catch (const std::exception &error) {
            reconciliation_error = "Unable to register saved profiles: " + std::string(error.what());
        }
    }
    // Only durable intents authorize cleanup. Untracked native profiles are
    // preserved, including registrations which predate a rejected import.
    if (reconciliation_error != last_reconciliation_error_) {
        logger_->Write(reconciliation_error.empty() ? LogLevel::info : LogLevel::error, LogCategory::profiles,
            reconciliation_error.empty() ? "Profile reconciliation recovered" : reconciliation_error);
        last_reconciliation_error_ = reconciliation_error;
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
    std::lock_guard lock(mutex_);
    snapshot_.tunnels = std::move(tunnels);
    snapshot_.tunnel_available = true;
    snapshot_.tunnel_observation_errors = observation_errors;
    snapshot_.reconciliation_error = std::move(reconciliation_error);
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
        register_missing_profiles_ = true;
    });
}
std::shared_ptr<ProfileEditor> AppSession::CreateEditor(const std::string &id) const {
    std::lock_guard lock(mutex_);
    if (!snapshot_.loaded || snapshot_.foreground_busy) return {};
    for (const auto &profile : editable_profiles_) {
        if (profile.id == id) return std::make_shared<ProfileEditor>(profile);
    }
    return {};
}
void AppSession::SaveEditor(std::shared_ptr<ProfileEditor> editor) {
    if (!editor || !editor->BeginSave()) return;
    if (!Post([this, editor] {
        try {
            profiles_.Update(editor->Original(), editor->Snapshot().draft,
                [this](const Profile &profile) {
                    tunnel_->ValidateUpdate(profile);
                    tunnel_->Save(profile);
                }, [this](const Profile &profile) {
                    tunnel_->ValidateUpdate(profile);
                });
            editor->FinishSave(true);
        } catch (...) {
            editor->FinishSave(false);
        }
    })) editor->FinishSave(false);
}
void AppSession::Import(std::vector<std::filesystem::path> paths) {
    ImportFiles(std::make_shared<ConfigurationFiles>(std::move(paths)));
}
void AppSession::ImportFiles(std::shared_ptr<const ConfigurationFiles> files) {
    if (!files || (!files->Count() && !files->selection_failures)) return;
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
        std::size_t failures = files->selection_failures;
        for (std::size_t index = 0; index < files->Count(); ++index) {
            {
                std::lock_guard lock(mutex_);
                if (stopping_) return;
            }
            try {
                logger_->Write(LogLevel::info, LogCategory::profiles, "Import profile...");
                const auto source = files->Read(index);
                // Registration follows the injected strategy on every platform,
                // including fake tunnels used by portable tests and demo mode.
                profiles_.ImportText(source.text, source.name, [this](const Profile &value) {
                    tunnel_->Register(value);
                }, [this](const std::string &id) {
                    tunnel_->RollbackRegistration(id);
                }, [this](const Profile &value) {
                    tunnel_->ValidateNew(value);
                });
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
            tunnel_->CancelPending(id);
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
        for (const auto &transaction : profiles_.PendingTransactions()) {
            if (transaction.id == id) throw std::runtime_error("Profile recovery is still pending.");
        }
        const auto profile = profiles_.Find(id);
        if (original && profile != *original) throw std::runtime_error("Profile changed during interactive login.");
        std::optional<Partout::TunnelCredentials> authentication;
        if (credentials) authentication = Partout::TunnelCredentials{credentials->username, credentials->password};
        tunnel_->Connect(profile, std::move(authentication));
    }, AppErrorContext::tunnel);
}
void AppSession::Disconnect(std::string id) {
    Post([this, id = std::move(id)] {
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
