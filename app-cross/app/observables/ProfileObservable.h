// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppProfileHeader.h"
#include "../business/managers/ProfileManager.h"
#include "../business/strategy/ConfigurationFiles.h"
#include "Worker.h"
#include "SnapshotTracker.h"
#include "ProfileEditor.h"

namespace Passepartout {
class ProfileObservable final {
public:
    enum class OperationErrorContext { general, import };
    struct State final {
        std::vector<Models::AppProfileHeader> profiles;
        bool loaded = false;
        // Queued/running profile operations, independent of tunnel work.
        bool busy = false;
        std::optional<OperationErrorContext> operation_error;
    };
    using Cursor = SnapshotTracker<State>::Cursor;

    ProfileObservable(Worker &executor, ProfileManager &manager);
    ~ProfileObservable();
    void Cancel();
    static bool CanRemove(const State &state, const std::vector<std::string> &ids);
    static bool CanSave(const State &state, const std::string &id);
    std::shared_ptr<ProfileEditor> CreateEditor(const std::string &id) const;
    void SaveEditor(std::shared_ptr<ProfileEditor> editor);
    void Load();
    void Import(std::vector<std::filesystem::path> paths);
    void ImportFiles(std::shared_ptr<const ConfigurationFiles> files);
    void ImportFailed();
    void Remove(std::vector<std::string> ids);
    State Snapshot() const;
    std::optional<State> SnapshotIfChanged(Cursor &cursor) const;
    void ClearOperationError();
    std::optional<Profile> FindProfile(const std::string &id) const;
private:
    bool Post(std::function<void()> operation, OperationErrorContext context = OperationErrorContext::general);
    void FinishOperation();
    void OnUpdate(const Models::Event &event);
    Worker &executor_;
    ProfileManager &manager_;
    std::size_t profile_subscription_;
    mutable std::mutex mutex_;
    State snapshot_;
    SnapshotTracker<State> changes_;
    std::size_t pending_operations_ = 0;
    std::vector<Profile> published_profiles_;
    std::shared_ptr<const ConfigurationFiles> importing_files_;
};
}
