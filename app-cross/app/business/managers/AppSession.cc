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
                       std::unique_ptr<TunnelStrategy> tunnel, std::shared_ptr<AppLogger> logger,
                       std::unique_ptr<ProfileJournal> journal, std::chrono::milliseconds recoveryDelay)
    : recoveryDelay_(recoveryDelay), logger_(std::move(logger)), profiles_(std::move(repository), std::move(importer), std::move(journal)),
      tunnel_(std::move(tunnel), logger_) {
    logger_->Write(LogLevel::info, "core", "Start application session");
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
        importing = importingFiles_;
    }
    if (importing) importing->Cancel();
    wake_.notify_all();
    tunnel_.Cancel();
    worker_.join();
    logger_->Write(LogLevel::info, "core", "Finished application session");
}
AppSnapshot AppSession::Snapshot() const {
    std::lock_guard lock(mutex_);
    return snapshot_;
}
void AppSession::ApplyPreferences(Models::AppPreferences preferences) {
    Post([this, preferences = std::move(preferences)] {
        pendingPreferences_ = preferences;
        tunnel_.ApplyPreferences(*pendingPreferences_);
        pendingPreferences_.reset();
    }, AppErrorContext::tunnel);
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
        if (!error.empty()) logger_->Write(LogLevel::error, "core", "Unable to execute operation");
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
                tunnelError.empty() ? "Tunnel observation recovered" : "Unable to fetch tunnel state");
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
std::string AppSession::RecoverProfiles() {
    std::string error;
    for (const auto &transaction : profiles_.PendingTransactions()) {
        auto &retry = recoveryRetries_[transaction.id];
        if (std::chrono::steady_clock::now() < retry.next) {
            error = retry.error;
            continue;
        }
        try {
            profiles_.Recover(transaction, [this](const ProfileTransaction &pending) {
                if (pending.removal) tunnel_.Remove(pending.id);
                else if (pending.previous) {
                    tunnel_.ValidateUpdate(*pending.previous);
                    tunnel_.Save(*pending.previous);
                } else tunnel_.RollbackRegistration(pending.id);
            });
            recoveryRetries_.erase(transaction.id);
        } catch (...) {
            retry.attempts = std::min(retry.attempts + 1, 5u);
            retry.next = std::chrono::steady_clock::now() + recoveryDelay_ * (1u << retry.attempts);
            retry.error = "Unable to recover profile " + transaction.id + ". Recovery will be retried.";
            error = retry.error;
        }
    }
    std::vector<std::string> pendingIds;
    for (const auto &transaction : profiles_.PendingTransactions()) pendingIds.push_back(transaction.id);
    std::lock_guard lock(mutex_);
    snapshot_.recoveringProfiles = std::move(pendingIds);
    return error;
}
void AppSession::Publish() {
    std::string reconciliationError;
    if (Snapshot().loaded) reconciliationError = RecoverProfiles();
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
        editableProfiles_ = profiles_.Profiles();
    }
    auto tunnels = tunnel_.Fetch();
    if (registerMissingProfiles_) {
        const auto unavailable = tunnel_.ObservationErrors();
        try {
            for (const auto &profile : profiles_.Profiles()) {
                if (unavailable.find(profile.id) != unavailable.end()) continue;
                const auto state = Snapshot();
                if (std::find(state.recoveringProfiles.begin(), state.recoveringProfiles.end(), profile.id)
                    != state.recoveringProfiles.end()) continue;
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
    // Only durable intents authorize cleanup. Untracked native profiles are
    // preserved, including registrations which predate a rejected import.
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
            logger_->Write(LogLevel::info, "tunnel", "Profile " + tunnel.id + " status: " + tunnel.status.ToJson().Encode());
    }
    std::lock_guard lock(mutex_);
    snapshot_.tunnels = std::move(tunnels);
    snapshot_.tunnelAvailable = true;
    snapshot_.tunnelObservationErrors = observationErrors;
    snapshot_.reconciliationError = std::move(reconciliationError);
}

void AppSession::Load() {
    Post([this] {
        {
            std::lock_guard lock(mutex_);
            snapshot_.loaded = false;
        }
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
std::shared_ptr<ProfileEditor> AppSession::CreateEditor(const std::string &id) const {
    std::lock_guard lock(mutex_);
    if (!snapshot_.loaded || snapshot_.foregroundBusy) return {};
    for (const auto &profile : editableProfiles_) {
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
                    tunnel_.ValidateUpdate(profile);
                    tunnel_.Save(profile);
                }, [this](const Profile &profile) {
                    tunnel_.ValidateUpdate(profile);
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
    if (!files || (!files->Count() && !files->selectionFailures)) return;
    Post([this, files = std::move(files)] {
        {
            std::lock_guard lock(mutex_);
            if (stopping_) return;
            importingFiles_ = files;
        }
        struct ReleaseFiles {
            AppSession &session;
            ~ReleaseFiles() {
                std::lock_guard lock(session.mutex_);
                session.importingFiles_.reset();
            }
        } release{*this};
        // Process every supplied activation, even if one configuration fails.
        std::size_t failures = files->selectionFailures;
        for (std::size_t index = 0; index < files->Count(); ++index) {
            {
                std::lock_guard lock(mutex_);
                if (stopping_) return;
            }
            try {
                logger_->Write(LogLevel::info, "profiles", "Import profile...");
                const auto source = files->Read(index);
                // Registration follows the injected strategy on every platform,
                // including fake tunnels used by portable tests and demo mode.
                profiles_.ImportText(source.text, source.name, [this](const Profile &value) {
                    tunnel_.Register(value);
                }, [this](const std::string &id) {
                    tunnel_.RollbackRegistration(id);
                }, [this](const Profile &value) {
                    tunnel_.ValidateNew(value);
                });
                logger_->Write(LogLevel::info, "profiles", "Finished saving profile");
            } catch (const std::exception &) {
                logger_->Write(LogLevel::error, "profiles", "Unable to import profile");
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
        const std::set<std::string> uniqueIds(ids.begin(), ids.end());
        // A menu or confirmation can outlive its targets. Validate the entire
        // request before deleting anything, on the same worker as mutations.
        for (const auto &id : uniqueIds) profiles_.Find(id);
        for (const auto &id : uniqueIds) {
            logger_->Write(LogLevel::info, "profiles", "Remove profile");
            profiles_.Remove(id);
            tunnel_.CancelPending(id);
        }
    });
}
void AppSession::Connect(std::string id, std::optional<Partout::Models::OpenVpnCredentials> credentials,
    std::optional<Profile> original) {
    Post([this, id = std::move(id), credentials = std::move(credentials), original = std::move(original)] {
        if (pendingPreferences_) {
            tunnel_.ApplyPreferences(*pendingPreferences_);
            pendingPreferences_.reset();
        }
        for (const auto &transaction : profiles_.PendingTransactions()) {
            if (transaction.id == id) throw std::runtime_error("Profile recovery is still pending.");
        }
        const auto profile = profiles_.Find(id);
        if (original && profile != *original) throw std::runtime_error("Profile changed during interactive login.");
        tunnel_.Connect(profile, credentials);
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
}
