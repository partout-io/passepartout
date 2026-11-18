// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ProfileRepository.h"
#include "ProfileJournal.h"
#include <functional>
#include <memory>

namespace Passepartout {
// Keep import/configuration conversion in Partout, including in tests.
using ProfileImporter = std::function<Profile(const std::string &, const std::string &)>;
class ProfileManager {
public:
    ProfileManager(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
        std::unique_ptr<ProfileJournal> journal = std::make_unique<MemoryProfileJournal>());
    void Load();
    Profile Import(const std::filesystem::path &path,
        std::function<void(const Profile &)> registerProfile = {},
        std::function<void(const std::string &)> rollbackRegistration = {},
        std::function<void(const Profile &)> validateRegistration = {});
    Profile ImportText(const std::string &text, const std::string &name,
        std::function<void(const Profile &)> registerProfile = {},
        std::function<void(const std::string &)> rollbackRegistration = {},
        std::function<void(const Profile &)> validateRegistration = {});
    void Update(const Profile &original, const Profile &replacement,
        std::function<void(const Profile &)> saveRegistration,
        std::function<void(const Profile &)> validateRegistration);
    std::vector<ProfileTransaction> PendingTransactions();
    void Recover(const ProfileTransaction &transaction,
        std::function<void(const ProfileTransaction &)> recoverRegistration);
    void Remove(const std::string &id);
    const Profile &Find(const std::string &id) const;
    const std::vector<Profile> &Profiles() const;
private:
    void RestoreLocal(const ProfileTransaction &transaction);
    void RequireReady(const std::string &id);
    std::unique_ptr<ProfileRepository> repository_;
    ProfileImporter importer_;
    std::unique_ptr<ProfileJournal> journal_;
    std::vector<Profile> profiles_;
    bool loaded_ = false;
};
}
