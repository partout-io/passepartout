// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileManager.h"
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
    std::function<void(const Profile &)> register_profile,
    std::function<void(const std::string &)> rollback_registration,
    std::function<void(const Profile &)> validate_registration) {
    return ImportText(Profiles::ReadConfiguration(path), Profiles::ConfigurationName(path), std::move(register_profile),
        std::move(rollback_registration), std::move(validate_registration));
}

Profile ProfileManager::ImportText(const std::string &text, const std::string &name,
    std::function<void(const Profile &)> register_profile,
    std::function<void(const std::string &)> rollback_registration,
    std::function<void(const Profile &)> validate_registration) {
    if (!loaded_) throw std::runtime_error("Load the saved profiles before importing.");
    if (text.empty() || text.size() > 1024 * 1024 || text.find('\0') != std::string::npos)
        throw std::runtime_error("Invalid configuration content.");
    auto profile = importer_(text, name);
    if (profile.name.empty()) profile.name = name;
    Profiles::ValidateIdentity(profile);
    RequireReady(profile.id);
    // An import must not silently replace an existing profile, especially one
    // currently in use. Explicit replacement can be added as a separate action.
    for (const auto &existing : profiles_) {
        if (existing.id == profile.id) throw std::runtime_error("This profile is already imported.");
    }
    // Prepare the published collection before any external side effects.
    auto committed = profiles_;
    committed.push_back(profile);
    Profiles::Sort(committed);
    if (validate_registration) validate_registration(profile);
    journal_->Save({profile.id, std::nullopt, false});
    try {
        if (register_profile) register_profile(profile);
        repository_->Save(profile);
        journal_->Remove(profile.id);
    } catch (...) {
        const auto failure = std::current_exception();
        std::string cleanup_error;
        try {
            // Save may have written the object before failing on the index.
            repository_->Remove(profile.id);
        } catch (...) {
            cleanup_error = " Local import rollback failed.";
        }
        try {
            if (rollback_registration) rollback_registration(profile.id);
        } catch (...) {
            cleanup_error += " VPN registration rollback failed for " + profile.id + ".";
        }
        if (!cleanup_error.empty()) throw std::runtime_error("Unable to commit imported profile." + cleanup_error);
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
    std::function<void(const ProfileTransaction &)> recover_registration) {
    RestoreLocal(transaction);
    recover_registration(transaction);
    journal_->Remove(transaction.id);
    profiles_ = repository_->Fetch();
}

void ProfileManager::Update(const Profile &original, const Profile &replacement,
    std::function<void(const Profile &)> save_registration,
    std::function<void(const Profile &)> validate_registration) {
    RequireReady(original.id);
    if (original.id != replacement.id || Find(original.id) != original)
        throw std::runtime_error("The profile changed while it was being edited.");
    Profiles::ValidateIdentity(replacement);
    if (original == replacement) throw std::runtime_error("The profile has no changes.");
    validate_registration(original);
    auto committed = profiles_;
    for (auto &profile : committed) {
        if (profile.id == replacement.id) profile = replacement;
    }
    Profiles::Sort(committed);
    const ProfileTransaction transaction{original.id, original, false};
    journal_->Save(transaction);
    try {
        save_registration(replacement);
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
            save_registration(original);
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
