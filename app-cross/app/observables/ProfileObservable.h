// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppProfileHeader.h"
#include "../business/managers/ProfileManager.h"
#include "../business/models/ConfigurationFiles.h"
#include "../context/AppLogger.h"
#include "SerialExecutor.h"
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
        SerialExecutor::Activity activity;
    };
    using ChangeHandler = std::function<void(std::vector<Profile>, bool)>;
    ProfileObservable(SerialExecutor &executor, std::unique_ptr<ProfileManager> manager,
                      std::shared_ptr<AppLogger> logger
    );
    // Publishes initial state and subsequent results on the shared executor.
    void OnChange(ChangeHandler handler);
    void Cancel();
    static bool CanRemove(const State &state, const std::vector<std::string> &ids);
    static bool CanSave(const State &state, const std::string &id);
    std::optional<Profile> FindProfile(const std::string &id) const;
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
    bool Post(std::function<void()> operation, OperationErrorContext context = OperationErrorContext::general);
    void Publish();
    SerialExecutor &executor_;
    std::unique_ptr<ProfileManager> manager_;
    std::shared_ptr<AppLogger> logger_;
    mutable std::mutex mutex_;
    State snapshot_;
    std::vector<Profile> published_profiles_;
    ChangeHandler on_change_;
    std::shared_ptr<const ConfigurationFiles> importing_files_;
};
}
