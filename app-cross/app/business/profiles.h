// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <filesystem>
#include <functional>
#include <memory>
#include <vector>
#include <partout/models/TaggedProfile.h>

namespace Passepartout {
using Profile = Partout::Models::TaggedProfile;

class ProfileRepository {
public:
    virtual ~ProfileRepository() = default;
    virtual std::vector<Profile> Fetch() = 0;
    virtual void Save(const Profile &profile) = 0;
    virtual void Remove(const std::string &id) = 0;
};

class FileProfileRepository final : public ProfileRepository {
public:
    explicit FileProfileRepository(std::filesystem::path directory);
    std::vector<Profile> Fetch() override;
    void Save(const Profile &profile) override;
    void Remove(const std::string &id) override;
private:
    std::filesystem::path ObjectPath(const std::string &id) const;
    std::vector<Profile> ReadObjects();
    void PersistIndex(const std::vector<Profile> &profiles);
    void WriteAtomically(const std::filesystem::path &path, const std::string &content);
    std::filesystem::path root_;
    std::filesystem::path directory_;
};

// Keep import/configuration conversion in Partout, including in tests.
using ProfileImporter = std::function<Profile(const std::string &, const std::string &)>;
class ProfileManager {
public:
    ProfileManager(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer);
    void Load();
    Profile Import(const std::filesystem::path &path,
        std::function<void(const Profile &)> registerProfile = {},
        std::function<void(const std::string &)> rollbackRegistration = {});
    void Remove(const std::string &id);
    const Profile &Find(const std::string &id) const;
    const std::vector<Profile> &Profiles() const;
private:
    std::unique_ptr<ProfileRepository> repository_;
    ProfileImporter importer_;
    std::vector<Profile> profiles_;
    bool loaded_ = false;
};

std::string ReadConfiguration(const std::filesystem::path &path);
void ValidateProfileIdentity(const Profile &profile);
}
