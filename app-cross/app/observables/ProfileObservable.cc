// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileObservable.h"
#include "../context/AppLog.h"
#include "../business/strategy/ConfigurationFiles.h"
#include <algorithm>
#include <set>
#include <stdexcept>

namespace Passepartout {
ProfileObservable::ProfileObservable(Worker &executor, ProfileManager &manager)
    : executor_(executor), manager_(manager),
      profile_subscription_(manager.events.Subscribe([this](const Models::Event &event) { OnUpdate(event); })) {}

ProfileObservable::~ProfileObservable() {
    manager_.events.Unsubscribe(profile_subscription_);
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
    {
        std::lock_guard lock(mutex_);
        snapshot_.operation_error.reset();
        snapshot_.busy = true;
        ++pending_operations_;
        changes.Emit();
    }
    const auto accepted = executor_.Post([this, operation = std::move(operation), context] {
        try {
            operation();
        } catch (...) {
            AppLog::Write(AppLog::Level::error, AppLog::Category::profiles, "Unable to execute profile operation");
            std::lock_guard lock(mutex_);
            snapshot_.operation_error = context;
        }
        FinishOperation();
    });
    if (!accepted) FinishOperation();
    return accepted;
}

void ProfileObservable::FinishOperation() {
    std::lock_guard lock(mutex_);
    snapshot_.busy = --pending_operations_ != 0;
    changes.Emit();
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
            manager_.Update(editor->Original(), editor->Snapshot().draft);
            editor->FinishSave(true);
        } catch (...) {
            AppLog::Write(AppLog::Level::error, AppLog::Category::profiles, "Unable to save profile");
            // ProfileCoordinator presents this failure through the editor state.
            editor->FinishSave(false);
        }
    })) editor->FinishSave(false);
}

bool ProfileObservable::CanRemove(const State &state, const std::vector<std::string> &ids) {
    if (!state.loaded || state.busy || ids.empty()) return false;
    return std::all_of(ids.begin(), ids.end(), [&](const auto &id) {
        return std::any_of(state.profiles.begin(), state.profiles.end(), [&](const auto &profile) {
            return profile.id == id;
        });
    });
}

void ProfileObservable::OnUpdate(const Models::Event &event) {
    if (!std::holds_alternative<Models::ProfileEventReady>(event) &&
        !std::holds_alternative<Models::ProfileEventSave>(event) &&
        !std::holds_alternative<Models::ProfileEventDelete>(event)) return;
    const auto &profiles = manager_.Profiles();
    std::vector<Models::AppProfileHeader> headers;
    headers.reserve(profiles.size());
    for (const auto &profile : profiles) {
        headers.push_back(Profiles::Header(profile));
    }
    std::lock_guard lock(mutex_);
    snapshot_.profiles = std::move(headers);
    published_profiles_ = profiles;
    snapshot_.loaded = true;
    changes.Emit();
}

void ProfileObservable::Load() {
    Post([this] {
        {
            std::lock_guard lock(mutex_);
            snapshot_.loaded = false;
            changes.Emit();
        }
        AppLog::Write(AppLog::Level::info, AppLog::Category::profiles, "Reload local profiles...");
        manager_.Load();
        AppLog::Write(AppLog::Level::info, AppLog::Category::profiles, "Reloaded local profiles: " + std::to_string(manager_.Profiles().size()));
    });
}

std::optional<Profile> ProfileObservable::FindProfile(const std::string &id) const {
    std::lock_guard lock(mutex_);
    if (!snapshot_.loaded || snapshot_.busy) return {};
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
        struct ReleaseFiles final {
            ProfileObservable &session;
            ~ReleaseFiles() {
                std::lock_guard lock(session.mutex_);
                session.importing_files_.reset();
            }
        } release{*this};
        // Process every supplied activation, even if one configuration fails.
        std::size_t failures = files->SelectionFailures();
        for (std::size_t index = 0; index < files->Count(); ++index) {
            if (executor_.IsStopping()) return;
            try {
                AppLog::Write(AppLog::Level::info, AppLog::Category::profiles, "Import profile...");
                const auto source = files->Read(index);
                manager_.ImportText(source.text, source.name);
                AppLog::Write(AppLog::Level::info, AppLog::Category::profiles, "Finished saving profile");
            } catch (...) {
                AppLog::Write(AppLog::Level::error, AppLog::Category::profiles, "Unable to import profile");
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
        for (const auto &id : unique_ids) manager_.Find(id);
        for (const auto &id : unique_ids) {
            AppLog::Write(AppLog::Level::info, AppLog::Category::profiles, "Remove profile");
            manager_.Remove(id);
        }
    });
}

ProfileObservable::State ProfileObservable::Snapshot() const {
    std::lock_guard lock(mutex_);
    auto result = snapshot_;
    if (executor_.IsStopping()) result.busy = false;
    return result;
}

void ProfileObservable::ClearOperationError() {
    std::lock_guard lock(mutex_);
    snapshot_.operation_error.reset();
    changes.Emit();
}

}
