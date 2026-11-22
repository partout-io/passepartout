// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "FileProfileRepository.h"
#include "../extensions/AtomicFile.h"
#include <algorithm>
#include <stdexcept>
#include <set>

namespace Passepartout {
FileProfileRepository::FileProfileRepository(std::filesystem::path directory)
    : root_(std::move(directory)), directory_(root_ / "objects") {
    std::filesystem::create_directories(directory_);
#ifndef _WIN32
    std::filesystem::permissions(directory_.parent_path(), std::filesystem::perms::owner_all);
    std::filesystem::permissions(directory_, std::filesystem::perms::owner_all);
#endif
}

std::filesystem::path FileProfileRepository::ObjectPath(const std::string &id) const {
    if (!IsSafeProfileId(id)) throw std::runtime_error("Invalid profile identifier.");
    return directory_ / (id + ".json");
}

std::vector<Profile> FileProfileRepository::ReadObjects() {
    std::vector<Profile> profiles;
    std::set<std::string> identities;
    for (const auto &entry : std::filesystem::directory_iterator(directory_)) {
        if (entry.path().extension() != ".json") continue;
        if (!entry.is_regular_file() || entry.is_symlink())
            throw std::runtime_error("Invalid entry in the profile store.");
        try {
            auto profile = Profile::FromJson(Partout::Models::Json::Parse(ReadConfiguration(entry.path())));
            ValidateProfileIdentity(profile);
            const auto destination = ObjectPath(profile.id);
            if (destination.filename() != entry.path().filename())
                throw std::runtime_error("Profile identity does not match its filename.");
            if (!identities.insert(profile.id).second)
                throw std::runtime_error("Duplicate profile identity.");
            profiles.push_back(std::move(profile));
        } catch (...) {
            // Parser messages can contain configuration secrets.
            throw std::runtime_error("Unable to read a saved profile. The original file was preserved.");
        }
    }
    SortProfiles(profiles);
    return profiles;
}

void FileProfileRepository::PersistIndex(const std::vector<Profile> &profiles) {
    auto entries = Partout::Models::Json::Array();
    for (const auto &profile : profiles) {
        Partout::Models::Json entry = {{"id", profile.id}, {"name", profile.name}};
        if (profile.userInfo && profile.userInfo->IsObject()) {
            for (const auto *key : {"lastUpdate", "fingerprint"}) {
                const auto value = profile.userInfo->Find(key);
                if (!value || value->IsNull()) continue;
                if (std::string(key) == "fingerprint") {
                    if (value->IsPrimitive()) entry.Set(key, value->IsString() ? value->Get<std::string>() : value->Encode());
                } else {
                    entry.Set(key, *value);
                }
            }
        }
        entries.Append(std::move(entry));
    }
    WriteAtomicFile(root_ / "index.json", Partout::Models::Json{{"version", 1}, {"profiles", entries}}.Encode());
}

std::vector<Profile> FileProfileRepository::Fetch() {
    auto objects = ReadObjects();
    std::vector<std::string> orderedIds;
    bool rebuild = false;
    try {
        const auto index = Partout::Models::Json::Parse(ReadConfiguration(root_ / "index.json"));
        if (index.At("version") != 1 || !index.At("profiles").IsArray()) throw std::runtime_error("Invalid index");
        std::set<std::string> seen;
        for (const auto &entry : index.At("profiles").Elements()) {
            auto id = entry.At("id").Get<std::string>();
            entry.At("name").Get<std::string>();
            if (!IsSafeProfileId(id) || !seen.insert(id).second) throw std::runtime_error("Invalid index identity");
            orderedIds.push_back(std::move(id));
        }
    } catch (...) {
        rebuild = true;
    }
    for (const auto &profile : objects) {
        if (std::find(orderedIds.begin(), orderedIds.end(), profile.id) == orderedIds.end()) rebuild = true;
    }
    if (rebuild) {
        PersistIndex(objects);
        return objects;
    }
    std::vector<Profile> ordered;
    for (const auto &id : orderedIds) {
        const auto found = std::find_if(objects.begin(), objects.end(), [&](const auto &p) { return p.id == id; });
        if (found == objects.end()) throw std::runtime_error("An indexed profile is missing.");
        ordered.push_back(*found);
    }
    return ordered;
}

void FileProfileRepository::Save(const Profile &profile) {
    ValidateProfileIdentity(profile);
    auto profiles = ReadObjects();
    const auto path = ObjectPath(profile.id);
    if (std::filesystem::exists(path)) {
        try {
            const auto previous = Profile::FromJson(Partout::Models::Json::Parse(ReadConfiguration(path)));
            if (previous.id != profile.id) throw std::runtime_error("Conflicting profile identity");
        } catch (...) {
            throw std::runtime_error("The existing profile cannot be safely replaced.");
        }
    }
    const auto content = profile.ToJson().Encode();
    if (content.size() > MaxConfigurationBytes)
        throw std::runtime_error("The saved profile exceeds 1 MiB.");
    WriteAtomicFile(path, content);
    profiles.erase(std::remove_if(profiles.begin(), profiles.end(), [&](const auto &p) { return p.id == profile.id; }), profiles.end());
    profiles.push_back(profile);
    SortProfiles(profiles);
    PersistIndex(profiles);
}

void FileProfileRepository::Remove(const std::string &id) {
    auto profiles = ReadObjects();
    std::filesystem::remove(ObjectPath(id));
    profiles.erase(std::remove_if(profiles.begin(), profiles.end(), [&](const auto &p) { return p.id == id; }), profiles.end());
    PersistIndex(profiles);
}
}
