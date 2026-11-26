// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/ProfileRepository.h"
#include "Event.h"
#include <functional>
#include <map>
#include <memory>

namespace Passepartout {
// Keep import/configuration conversion in Partout, including in tests.
using ProfileImporter = std::function<Profile(const std::string &, const std::string &)>;
class ProfileManager final {
public:
    using EventHandler = std::function<void(const Models::Event &)>;
    // Subscribe before starting the shared worker; unsubscribe after stopping it.
    std::size_t Subscribe(EventHandler handler);
    void Unsubscribe(std::size_t subscription);
    ProfileManager(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer);
    void Load();
    Profile Import(const std::filesystem::path &path);
    Profile ImportText(const std::string &text, const std::string &name);
    void Update(const Profile &original, const Profile &replacement);
    void Remove(const std::string &id);
    const Profile &Find(const std::string &id) const;
    const std::vector<Profile> &Profiles() const;
private:
    void Emit(const Models::Event &event);
    std::map<std::size_t, EventHandler> handlers_;
    std::size_t next_subscription_ = 0;
    std::unique_ptr<ProfileRepository> repository_;
    ProfileImporter importer_;
    std::vector<Profile> profiles_;
    bool loaded_ = false;
};
}
