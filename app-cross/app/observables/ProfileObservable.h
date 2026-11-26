// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppProfileHeader.h"
#include "../business/managers/ProfileManager.h"
#include "../business/strategy/ConfigurationFiles.h"
#include "Worker.h"
#include "ProfileEditor.h"

namespace Passepartout {
class ProfileObservable final {
public:
    enum class OperationErrorContext { general, import };
    struct State final {
        std::vector<Models::AppProfileHeader> profiles;
        bool loaded = false;
        std::string operation_error;
        OperationErrorContext operation_error_context = OperationErrorContext::general;
        std::uint64_t revision = 0;
        Worker::Activity activity;
    };
    using ChangeHandler = std::function<void(std::vector<Profile>, bool)>;
    ProfileObservable(Worker &executor, std::unique_ptr<ProfileManager> manager);
    // Publishes initial state and subsequent results on the shared executor.
    void OnChange(ChangeHandler handler);
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
private:
    std::optional<Profile> FindProfile(const std::string &id) const;
    bool Post(std::function<void()> operation, OperationErrorContext context = OperationErrorContext::general);
    void Publish();
    Worker &executor_;
    std::unique_ptr<ProfileManager> manager_;
    mutable std::mutex mutex_;
    State snapshot_;
    std::vector<Profile> published_profiles_;
    // Accessed only on the shared worker.
    ChangeHandler on_change_;
    std::shared_ptr<const ConfigurationFiles> importing_files_;
};
}
