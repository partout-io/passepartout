// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "MainThread.h"
#include "../business/extensions/EventEmitter.h"
#include "AppProfileHeader.h"
#include "../business/managers/ProfileManager.h"
#include "../business/strategy/ConfigurationFiles.h"
#include "Worker.h"
#include "ProfileEditor.h"

namespace Passepartout {
class ProfileObservable final {
public:
    EventEmitter<> changes;
    enum class OperationErrorContext { general, import };
    struct State final {
        std::vector<Models::AppProfileHeader> profiles;
        bool loaded = false;
        // Queued/running profile operations, independent of tunnel work.
        bool busy = false;
        std::optional<OperationErrorContext> operation_error;
    };

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
    void ClearOperationError();
    std::optional<Profile> FindProfile(const std::string &id) const;
private:
    MainThread delivery_;
    bool Post(std::function<void()> operation, OperationErrorContext context = OperationErrorContext::general);
    void FinishOperation();
    void OnUpdate(const std::vector<Profile> &profiles);
    Worker &executor_;
    ProfileManager &manager_;
    std::size_t profile_subscription_;
    State snapshot_;
    std::size_t pending_operations_ = 0;
    std::vector<Profile> published_profiles_;
    std::vector<std::shared_ptr<const ConfigurationFiles>> importing_files_;
};
}
