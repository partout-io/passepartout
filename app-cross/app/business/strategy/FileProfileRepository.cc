// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "FileProfileRepository.h"
#include "../extensions/Models+Business.h"
#include <algorithm>
#include <stdexcept>
#include <set>

namespace {
constexpr const char ObjectsDirectory[] = "objects";
constexpr const char IndexFilename[] = "index.json";
constexpr const char ObjectExtension[] = ".json";
constexpr int IndexVersion = 1;

namespace IndexFields {
constexpr const char Version[] = "version";
constexpr const char Profiles[] = "profiles";
constexpr const char Id[] = "id";
constexpr const char Name[] = "name";
}

// Repository-owned wire records, matching Android's private index format.
struct IndexEntry final {
    std::string id;
    std::string name;
    std::optional<Partout::Json> last_update;
    std::optional<std::string> fingerprint;
    static IndexEntry FromProfile(const Passepartout::Profile &profile);
    static IndexEntry FromJson(const Partout::Json &json);
    Partout::Json ToJson() const;
};

struct IndexFile final {
    std::vector<IndexEntry> profiles;
    static IndexFile FromJson(const Partout::Json &json);
    Partout::Json ToJson() const;
};

IndexEntry IndexEntry::FromProfile(const Passepartout::Profile &profile) {
    IndexEntry entry{profile.id, profile.name, {}, {}};
    if (!profile.userInfo || !profile.userInfo->IsObject()) return entry;
    if (const auto value = profile.userInfo->Find(Passepartout::Profiles::LastUpdateKey)) {
        if (!value->IsNull()) entry.last_update = *value;
    }
    if (const auto value = profile.userInfo->Find(Passepartout::Profiles::FingerprintKey)) {
        if (!value->IsNull() && value->IsPrimitive())
            entry.fingerprint = value->IsString() ? value->Get<std::string>() : value->Encode();
    }
    return entry;
}

IndexEntry IndexEntry::FromJson(const Partout::Json &json) {
    IndexEntry entry{json.At(IndexFields::Id).Get<std::string>(), json.At(IndexFields::Name).Get<std::string>(), {}, {}};
    if (const auto value = json.Find(Passepartout::Profiles::LastUpdateKey)) {
        if (!value->IsNull()) entry.last_update = *value;
    }
    if (const auto value = json.Find(Passepartout::Profiles::FingerprintKey)) {
        if (!value->IsNull()) entry.fingerprint = value->Get<std::string>();
    }
    return entry;
}

Partout::Json IndexEntry::ToJson() const {
    Partout::Json json = {{IndexFields::Id, id}, {IndexFields::Name, name}};
    if (last_update) json.Set(Passepartout::Profiles::LastUpdateKey, *last_update);
    if (fingerprint) json.Set(Passepartout::Profiles::FingerprintKey, *fingerprint);
    return json;
}

IndexFile IndexFile::FromJson(const Partout::Json &json) {
    if (json.At(IndexFields::Version) != IndexVersion || !json.At(IndexFields::Profiles).IsArray())
        throw std::runtime_error("Invalid index");
    IndexFile index;
    for (const auto &entry : json.At(IndexFields::Profiles).Elements()) {
        index.profiles.push_back(IndexEntry::FromJson(entry));
    }
    return index;
}

Partout::Json IndexFile::ToJson() const {
    auto entries = Partout::Json::Array();
    for (const auto &entry : profiles) entries.Append(entry.ToJson());
    return {{IndexFields::Version, IndexVersion}, {IndexFields::Profiles, entries}};
}
}

namespace Passepartout {
FileProfileRepository::FileProfileRepository(std::filesystem::path directory)
    : objects_directory_(directory / ObjectsDirectory), index_file_(directory / IndexFilename) {
    std::filesystem::create_directories(objects_directory_);
#ifndef _WIN32
    std::filesystem::permissions(objects_directory_.parent_path(), std::filesystem::perms::owner_all);
    std::filesystem::permissions(objects_directory_, std::filesystem::perms::owner_all);
#endif
}

std::filesystem::path FileProfileRepository::ObjectPath(const std::string &id) const {
    if (!Profiles::IsSafeId(id)) throw std::runtime_error("Invalid profile identifier.");
    return objects_directory_ / (id + ObjectExtension);
}

std::vector<Profile> FileProfileRepository::ReadObjects() {
    std::vector<Profile> profiles;
    std::set<std::string> identities;
    for (const auto &entry : std::filesystem::directory_iterator(objects_directory_)) {
        if (entry.path().extension() != ObjectExtension) continue;
        if (!entry.is_regular_file() || entry.is_symlink())
            throw std::runtime_error("Invalid entry in the profile store.");
        try {
            auto profile = Profile::FromJson(Partout::Json::Parse(Profiles::ReadConfiguration(entry.path())));
            Profiles::ValidateIdentity(profile);
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
    Profiles::Sort(profiles);
    return profiles;
}

void FileProfileRepository::PersistIndex(const std::vector<Profile> &profiles) {
    IndexFile index;
    for (const auto &profile : profiles) index.profiles.push_back(IndexEntry::FromProfile(profile));
    AtomicFile::Write(index_file_, index.ToJson().Encode());
}

std::vector<Profile> FileProfileRepository::Fetch() {
    auto objects = ReadObjects();
    std::vector<std::string> ordered_ids;
    bool rebuild = false;
    try {
        const auto index = IndexFile::FromJson(Partout::Json::Parse(Profiles::ReadConfiguration(index_file_)));
        std::set<std::string> seen;
        for (const auto &entry : index.profiles) {
            if (!Profiles::IsSafeId(entry.id) || !seen.insert(entry.id).second)
                throw std::runtime_error("Invalid index identity");
            ordered_ids.push_back(entry.id);
        }
    } catch (...) {
        rebuild = true;
    }
    for (const auto &profile : objects) {
        if (std::find(ordered_ids.begin(), ordered_ids.end(), profile.id) == ordered_ids.end()) rebuild = true;
    }
    if (rebuild) {
        PersistIndex(objects);
        return objects;
    }
    std::vector<Profile> ordered;
    for (const auto &id : ordered_ids) {
        const auto found = std::find_if(objects.begin(), objects.end(), [&](const auto &p) { return p.id == id; });
        if (found == objects.end()) throw std::runtime_error("An indexed profile is missing.");
        ordered.push_back(*found);
    }
    return ordered;
}

void FileProfileRepository::Save(const Profile &profile) {
    Profiles::ValidateIdentity(profile);
    auto profiles = ReadObjects();
    const auto path = ObjectPath(profile.id);
    if (std::filesystem::exists(path)) {
        try {
            const auto previous = Profile::FromJson(Partout::Json::Parse(Profiles::ReadConfiguration(path)));
            if (previous.id != profile.id) throw std::runtime_error("Conflicting profile identity");
        } catch (...) {
            throw std::runtime_error("The existing profile cannot be safely replaced.");
        }
    }
    const auto content = profile.ToJson().Encode();
    if (content.size() > Profiles::MaxConfigurationBytes)
        throw std::runtime_error("The saved profile exceeds the configuration size limit.");
    AtomicFile::Write(path, content);
    profiles.erase(std::remove_if(profiles.begin(), profiles.end(), [&](const auto &p) { return p.id == profile.id; }), profiles.end());
    profiles.push_back(profile);
    Profiles::Sort(profiles);
    PersistIndex(profiles);
}

void FileProfileRepository::Remove(const std::string &id) {
    auto profiles = ReadObjects();
    std::filesystem::remove(ObjectPath(id));
    profiles.erase(std::remove_if(profiles.begin(), profiles.end(), [&](const auto &p) { return p.id == id; }), profiles.end());
    PersistIndex(profiles);
}
}
