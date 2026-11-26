// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/ProfileRepository.h"
#include <functional>
#include <memory>

namespace Passepartout {
// Keep import/configuration conversion in Partout, including in tests.
using ProfileImporter = std::function<Profile(const std::string &, const std::string &)>;
class ProfileManager final {
public:
    ProfileManager(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer);
    void Load();
    Profile Import(const std::filesystem::path &path);
    Profile ImportText(const std::string &text, const std::string &name);
    void Update(const Profile &original, const Profile &replacement);
    void Remove(const std::string &id);
    const Profile &Find(const std::string &id) const;
    const std::vector<Profile> &Profiles() const;
private:
    std::unique_ptr<ProfileRepository> repository_;
    ProfileImporter importer_;
    std::vector<Profile> profiles_;
    bool loaded_ = false;
};
}
