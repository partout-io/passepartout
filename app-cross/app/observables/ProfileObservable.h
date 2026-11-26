// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/models/AppSnapshot.h"
#include "ProfileEditor.h"
#include "../business/models/ConfigurationFiles.h"

namespace Passepartout {
class AppSession;

class ProfileObservable final {
public:
    explicit ProfileObservable(AppSession &session) : session_(session) {}
    static bool CanRemove(const AppSnapshot &state, const std::vector<std::string> &ids);
    static bool CanSave(const AppSnapshot &state, const std::string &id);
    std::shared_ptr<ProfileEditor> CreateEditor(const std::string &id) const;
    void SaveEditor(std::shared_ptr<ProfileEditor> editor);
    void Load();
    void Import(std::vector<std::filesystem::path> paths);
    void ImportFiles(std::shared_ptr<const ConfigurationFiles> files);
    void ImportFailed();
    void Remove(std::vector<std::string> ids);
    AppSnapshot Snapshot() const;
    void ClearError();
private:
    AppSession &session_;
};
}
