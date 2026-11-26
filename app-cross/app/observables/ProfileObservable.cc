// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileObservable.h"
#include "../business/strategy/ConfigurationFiles.h"
#include <algorithm>
#include <set>
#include <stdexcept>
#include <type_traits>

namespace Passepartout {
ProfileObservable::ProfileObservable(SerialExecutor &executor, std::unique_ptr<ProfileManager> manager,
                                     std::shared_ptr<AppLogger> logger
) : executor_(executor), manager_(std::move(manager)), logger_(std::move(logger)) {
}

void ProfileObservable::OnChange(ChangeHandler handler) {
    executor_.Dispatch([this, handler = std::move(handler)] {
        {
            std::lock_guard lock(mutex_);
            on_change_ = handler;
        }
        Publish();
    }, false);
}

void ProfileObservable::Cancel() {
    std::shared_ptr<const ConfigurationFiles> importing;
    {
        std::lock_guard lock(mutex_);
        importing = importing_files_;
    }
    if (importing) importing->Cancel();
}

bool ProfileObservable::Post(std::function<void()> operation, OperationErrorContext context) {
    ClearOperationError();
    return executor_.Post([this, operation = std::move(operation), context] {
        std::string error;
        try {
            operation();
        } catch (const std::exception &failure) {
            error = failure.what();
        } catch (...) {
            error = "The operation failed.";
        }
        if (!error.empty()) logger_->Write(LogLevel::error, LogCategory::profiles, "Unable to execute profile operation");
        {
            std::lock_guard lock(mutex_);
            snapshot_.operation_error = std::move(error);
            snapshot_.operation_error_context = context;
            ++snapshot_.revision;
        }
        Publish();
    });
}

bool ProfileObservable::CanSave(const State &state, const std::string &id) {
    return CanRemove(state, {id});
}

std::shared_ptr<ProfileEditor> ProfileObservable::CreateEditor(const std::string &id) const {
    const auto profile = FindProfile(id);
    return profile ? std::make_shared<ProfileEditor>(*profile) : nullptr;
}

void ProfileObservable::SaveEditor(std::shared_ptr<ProfileEditor> editor) {
    if (!editor || !CanSave(Snapshot(), editor->Original().id) || !editor->BeginSave()) return;
    if (!Post([this, editor] {
        try {
            manager_->Update(editor->Original(), editor->Snapshot().draft);
            editor->FinishSave(true);
        } catch (...) {
            editor->FinishSave(false);
            throw;
        }
    })) editor->FinishSave(false);
}

bool ProfileObservable::CanRemove(const State &state, const std::vector<std::string> &ids) {
    if (!state.loaded || state.activity.foreground || ids.empty()) return false;
    return std::all_of(ids.begin(), ids.end(), [&](const auto &id) {
        return std::any_of(state.profiles.begin(), state.profiles.end(), [&](const auto &profile) {
            return profile.id == id;
        });
    });
}

void ProfileObservable::Publish() {
    try {
        std::vector<Models::AppProfileHeader> headers;
        for (const auto &profile : manager_->Profiles()) {
            Models::AppProfileHeader header{};
            header.id = profile.id;
            header.name = profile.name;
            header.fingerprint = profile.id;
            if (profile.userInfo && profile.userInfo->IsObject()) {
                const auto fingerprint = profile.userInfo->Find(Profiles::FingerprintKey);
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
            published_profiles_ = manager_->Profiles();
        }
        ChangeHandler handler;
        bool loaded;
        {
            std::lock_guard lock(mutex_);
            handler = on_change_;
            loaded = snapshot_.loaded;
        }
        if (handler) handler(manager_->Profiles(), loaded);
    } catch (...) {
        std::lock_guard lock(mutex_);
        snapshot_.operation_error = "Unable to publish saved profiles.";
        snapshot_.operation_error_context = OperationErrorContext::general;
        ++snapshot_.revision;
    }
}

void ProfileObservable::Load() {
    Post([this] {
        {
            std::lock_guard lock(mutex_);
            snapshot_.loaded = false;
        }
        logger_->Write(LogLevel::info, LogCategory::profiles, "Reload local profiles...");
        manager_->Load();
        logger_->Write(LogLevel::info, LogCategory::profiles, "Reloaded local profiles: " + std::to_string(manager_->Profiles().size()));
        {
            std::lock_guard lock(mutex_);
            snapshot_.loaded = true;
        }
    });
}

std::optional<Profile> ProfileObservable::FindProfile(const std::string &id) const {
    if (executor_.Snapshot().foreground) return {};
    std::lock_guard lock(mutex_);
    if (!snapshot_.loaded) return {};
    for (const auto &profile : published_profiles_) {
        if (profile.id == id) return profile;
    }
    return {};
}

void ProfileObservable::Import(std::vector<std::filesystem::path> paths) {
    ImportFiles(std::make_shared<FileConfigurationFiles>(std::move(paths)));
}

void ProfileObservable::ImportFiles(std::shared_ptr<const ConfigurationFiles> files) {
    if (!files || (!files->Count() && !files->SelectionFailures())) return;
    Post([this, files = std::move(files)] {
        {
            std::lock_guard lock(mutex_);
            if (executor_.IsStopping()) return;
            importing_files_ = files;
        }
        struct ReleaseFiles {
            ProfileObservable &session;
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
                if (executor_.IsStopping()) return;
            }
            try {
                logger_->Write(LogLevel::info, LogCategory::profiles, "Import profile...");
                const auto source = files->Read(index);
                manager_->ImportText(source.text, source.name);
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
    }, OperationErrorContext::import);
}

void ProfileObservable::ImportFailed() {
    Post([] {
        throw std::runtime_error("Configuration selection failed.");
    }, OperationErrorContext::import);
}

void ProfileObservable::Remove(std::vector<std::string> ids) {
    Post([this, ids = std::move(ids)] {
        const std::set<std::string> unique_ids(ids.begin(), ids.end());
        // A menu or confirmation can outlive its targets. Validate the entire
        // request before deleting anything, on the same worker as mutations.
        for (const auto &id : unique_ids) manager_->Find(id);
        for (const auto &id : unique_ids) {
            logger_->Write(LogLevel::info, LogCategory::profiles, "Remove profile");
            manager_->Remove(id);
        }
    });
}

ProfileObservable::State ProfileObservable::Snapshot() const {
    const auto activity = executor_.Snapshot();
    std::lock_guard lock(mutex_);
    auto result = snapshot_;
    result.activity = activity;
    return result;
}

void ProfileObservable::ClearOperationError() {
    std::lock_guard lock(mutex_);
    snapshot_.operation_error.clear();
    ++snapshot_.revision;
}
}
