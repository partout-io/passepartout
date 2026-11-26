// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileManager.h"
#include <algorithm>
#include <stdexcept>

namespace Passepartout {
ProfileManager::ProfileManager(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer)
    : repository_(std::move(repository)), importer_(std::move(importer)) {}

std::size_t ProfileManager::Subscribe(EventHandler handler) {
    const auto subscription = ++next_subscription_;
    handlers_.emplace(subscription, std::move(handler));
    return subscription;
}

void ProfileManager::Unsubscribe(std::size_t subscription) {
    handlers_.erase(subscription);
}

void ProfileManager::Emit(const Models::Event &event) {
    for (const auto &[subscription, handler] : handlers_) handler(event);
}

void ProfileManager::Load() {
    auto profiles = repository_->Fetch();
    profiles_ = std::move(profiles);
    loaded_ = true;
    Emit(Models::ProfileEventReady{});
}

Profile ProfileManager::Import(const std::filesystem::path &path) {
    return ImportText(Profiles::ReadConfiguration(path), Profiles::ConfigurationName(path));
}

Profile ProfileManager::ImportText(const std::string &text, const std::string &name) {
    if (!loaded_) throw std::runtime_error("Load the saved profiles before importing.");
    if (text.empty() || text.size() > Profiles::MaxConfigurationBytes || text.find('\0') != std::string::npos)
        throw std::runtime_error("Invalid configuration content.");
    auto profile = importer_(text, name);
    if (profile.name.empty()) profile.name = name;
    Profiles::ValidateIdentity(profile);
    // An import must not silently replace an existing profile, especially one
    // currently in use. Explicit replacement can be added as a separate action.
    for (const auto &existing : profiles_) {
        if (existing.id == profile.id) throw std::runtime_error("This profile is already imported.");
    }
    // Prepare the published collection before any external side effects.
    auto committed = profiles_;
    committed.push_back(profile);
    Profiles::Sort(committed);
    repository_->Save(profile);
    profiles_.swap(committed);
    Models::ProfileEventSave event;
    event.profile = profile;
    Emit(event);
    return profile;
}

void ProfileManager::Update(const Profile &original, const Profile &replacement) {
    if (original.id != replacement.id || Find(original.id) != original)
        throw std::runtime_error("The profile changed while it was being edited.");
    Profiles::ValidateIdentity(replacement);
    if (original == replacement) throw std::runtime_error("The profile has no changes.");
    auto committed = profiles_;
    for (auto &profile : committed) {
        if (profile.id == replacement.id) profile = replacement;
    }
    Profiles::Sort(committed);
    repository_->Save(replacement);
    profiles_.swap(committed);
    Models::ProfileEventSave event;
    event.profile = replacement;
    event.previous = original;
    Emit(event);
}

void ProfileManager::Remove(const std::string &id) {
    Find(id);
    repository_->Remove(id);
    profiles_.erase(std::remove_if(profiles_.begin(), profiles_.end(), [&](const auto &p) {
        return p.id == id;
    }), profiles_.end());
    Models::ProfileEventDelete event;
    event.ids = {id};
    Emit(event);
}

const Profile &ProfileManager::Find(const std::string &id) const {
    for (const auto &profile : profiles_) {
        if (profile.id == id) return profile;
    }
    throw std::runtime_error("The profile no longer exists.");
}

const std::vector<Profile> &ProfileManager::Profiles() const {
    return profiles_;
}
}
