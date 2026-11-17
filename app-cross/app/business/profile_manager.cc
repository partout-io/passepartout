// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "profile_manager.h"
#include <algorithm>
#include <exception>
#include <stdexcept>

namespace Passepartout {
ProfileManager::ProfileManager(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
    std::unique_ptr<ProfileJournal> journal)
    : repository_(std::move(repository)), importer_(std::move(importer)), journal_(std::move(journal)) {}
void ProfileManager::Load() {
    // Repair the authoritative objects/index before exposing a collection.
    // Native recovery can remain pending without hiding unrelated local profiles.
    for (const auto &transaction : journal_->Fetch()) RestoreLocal(transaction);
    auto profiles = repository_->Fetch();
    profiles_ = std::move(profiles);
    loaded_ = true;
}
Profile ProfileManager::Import(const std::filesystem::path &path,
    std::function<void(const Profile &)> registerProfile,
    std::function<void(const std::string &)> rollbackRegistration,
    std::function<void(const Profile &)> validateRegistration) {
    return ImportText(ReadConfiguration(path), path.stem().u8string(), std::move(registerProfile),
        std::move(rollbackRegistration), std::move(validateRegistration));
}
Profile ProfileManager::ImportText(const std::string &text, const std::string &name,
    std::function<void(const Profile &)> registerProfile,
    std::function<void(const std::string &)> rollbackRegistration,
    std::function<void(const Profile &)> validateRegistration) {
    if (!loaded_) throw std::runtime_error("Load the saved profiles before importing.");
    if (text.empty() || text.size() > 1024 * 1024 || text.find('\0') != std::string::npos)
        throw std::runtime_error("Invalid configuration content.");
    auto profile = importer_(text, name);
    if (profile.name.empty()) profile.name = name;
    ValidateProfileIdentity(profile);
    RequireReady(profile.id);
    // An import must not silently replace an existing profile, especially one
    // currently in use. Explicit replacement can be added as a separate action.
    for (const auto &existing : profiles_) {
        if (existing.id == profile.id) throw std::runtime_error("This profile is already imported.");
    }
    // Prepare the published collection before any external side effects.
    auto committed = profiles_;
    committed.push_back(profile);
    SortProfiles(committed);
    if (validateRegistration) validateRegistration(profile);
    journal_->Save({profile.id, std::nullopt, false});
    try {
        if (registerProfile) registerProfile(profile);
        repository_->Save(profile);
        journal_->Remove(profile.id);
    } catch (...) {
        const auto failure = std::current_exception();
        std::string cleanupError;
        try {
            // Save may have written the object before failing on the index.
            repository_->Remove(profile.id);
        } catch (...) {
            cleanupError = " Local import rollback failed.";
        }
        try {
            if (rollbackRegistration) rollbackRegistration(profile.id);
        } catch (...) {
            cleanupError += " VPN registration rollback failed for " + profile.id + ".";
        }
        if (!cleanupError.empty()) throw std::runtime_error("Unable to commit imported profile." + cleanupError);
        journal_->Remove(profile.id);
        std::rethrow_exception(failure);
    }
    profiles_.swap(committed);
    return profile;
}
void ProfileManager::RequireReady(const std::string &id) {
    for (const auto &transaction : journal_->Fetch()) {
        if (transaction.id == id) throw std::runtime_error("Profile recovery is still pending.");
    }
}
std::vector<ProfileTransaction> ProfileManager::PendingTransactions() {
    return journal_->Fetch();
}
void ProfileManager::RestoreLocal(const ProfileTransaction &transaction) {
    if (transaction.previous && !transaction.removal) repository_->Save(*transaction.previous);
    else repository_->Remove(transaction.id);
}
void ProfileManager::Recover(const ProfileTransaction &transaction,
    std::function<void(const ProfileTransaction &)> recoverRegistration) {
    RestoreLocal(transaction);
    recoverRegistration(transaction);
    journal_->Remove(transaction.id);
    profiles_ = repository_->Fetch();
}
void ProfileManager::Update(const Profile &original, const Profile &replacement,
    std::function<void(const Profile &)> saveRegistration,
    std::function<void(const Profile &)> validateRegistration) {
    RequireReady(original.id);
    if (original.id != replacement.id || Find(original.id) != original)
        throw std::runtime_error("The profile changed while it was being edited.");
    ValidateProfileIdentity(replacement);
    if (original == replacement) throw std::runtime_error("The profile has no changes.");
    validateRegistration(original);
    auto committed = profiles_;
    for (auto &profile : committed) {
        if (profile.id == replacement.id) profile = replacement;
    }
    SortProfiles(committed);
    const ProfileTransaction transaction{original.id, original, false};
    journal_->Save(transaction);
    try {
        saveRegistration(replacement);
        repository_->Save(replacement);
        journal_->Remove(original.id);
    } catch (...) {
        const auto failure = std::current_exception();
        bool restored = true;
        try {
            RestoreLocal(transaction);
        } catch (...) {
            restored = false;
        }
        try {
            saveRegistration(original);
        } catch (...) {
            restored = false;
        }
        if (restored) journal_->Remove(original.id);
        if (!restored) throw std::runtime_error("Profile update recovery is pending. The draft was retained.");
        std::rethrow_exception(failure);
    }
    profiles_.swap(committed);
}
void ProfileManager::Remove(const std::string &id) {
    Find(id);
    RequireReady(id);
    journal_->Save({id, std::nullopt, true});
    repository_->Remove(id);
    profiles_.erase(std::remove_if(profiles_.begin(), profiles_.end(), [&](const auto &p) {
        return p.id == id;
    }), profiles_.end());
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
