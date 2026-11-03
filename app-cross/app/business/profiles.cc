// SPDX-License-Identifier: GPL-3.0
#include "profiles.h"
#include <algorithm>
#include <cerrno>
#include <cstdio>
#include <fstream>
#include <stdexcept>
#ifdef _WIN32
#include <windows.h>
#else
#include <fcntl.h>
#include <unistd.h>
#endif

namespace Passepartout {
namespace {
constexpr std::size_t MaxConfigurationBytes = 1024 * 1024;
bool IsSafeId(const std::string &id) {
    return !id.empty() && id.size() <= 128 &&
        std::all_of(id.begin(), id.end(), [](unsigned char c) {
            return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') || c == '-' || c == '_';
        });
}
void Sort(std::vector<Profile> &profiles) {
    std::sort(profiles.begin(), profiles.end(), [](const auto &a, const auto &b) {
        return a.name == b.name ? a.id < b.id : a.name < b.name;
    });
}
}

void ValidateProfileIdentity(const Profile &profile) {
    if (!IsSafeId(profile.id) || profile.name.empty())
        throw std::runtime_error("The profile has an invalid identity or an empty name.");
}

std::string ReadConfiguration(const std::filesystem::path &path) {
    if (!std::filesystem::is_regular_file(path))
        throw std::runtime_error("The configuration is not a regular file.");
    std::ifstream input(path, std::ios::binary);
    if (!input) throw std::runtime_error("Unable to open the configuration file.");
    // Bound the actual read, including files that grow after opening.
    std::string content(MaxConfigurationBytes + 1, '\0');
    input.read(content.data(), static_cast<std::streamsize>(content.size()));
    const auto size = input.gcount();
    if (input.bad() || size <= 0 || size > static_cast<std::streamsize>(MaxConfigurationBytes))
        throw std::runtime_error("The configuration must be a nonempty file no larger than 1 MiB.");
    content.resize(static_cast<std::size_t>(size));
    if (content.find('\0') != std::string::npos)
        throw std::runtime_error("The configuration contains invalid text.");
    return content;
}

FileProfileRepository::FileProfileRepository(std::filesystem::path directory)
    : directory_(std::move(directory) / "objects") {
    std::filesystem::create_directories(directory_);
#ifndef _WIN32
    std::filesystem::permissions(directory_.parent_path(), std::filesystem::perms::owner_all);
    std::filesystem::permissions(directory_, std::filesystem::perms::owner_all);
#endif
}

std::filesystem::path FileProfileRepository::ObjectPath(const std::string &id) const {
    if (!IsSafeId(id)) throw std::runtime_error("Invalid profile identifier.");
    // Prefix avoids reserved DOS filenames even if an imported id is not a UUID.
    return directory_ / ("profile-" + id + ".json");
}

std::vector<Profile> FileProfileRepository::Fetch() {
    std::vector<Profile> profiles;
    for (const auto &entry : std::filesystem::directory_iterator(directory_)) {
        if (entry.path().extension() != ".json") continue;
        if (!entry.is_regular_file() || entry.is_symlink())
            throw std::runtime_error("Invalid entry in the profile store.");
        try {
            auto profile = Profile::FromJson(nlohmann::json::parse(ReadConfiguration(entry.path())));
            ValidateProfileIdentity(profile);
            if (ObjectPath(profile.id).filename() != entry.path().filename())
                throw std::runtime_error("Profile identity does not match its filename.");
            profiles.push_back(std::move(profile));
        } catch (...) {
            // Parser messages can contain configuration secrets.
            throw std::runtime_error("Unable to read a saved profile. The original file was preserved.");
        }
    }
    Sort(profiles);
    return profiles;
}

void FileProfileRepository::Save(const Profile &profile) {
    ValidateProfileIdentity(profile);
    const auto path = ObjectPath(profile.id);
    if (std::filesystem::exists(path)) {
        try {
            const auto previous = Profile::FromJson(nlohmann::json::parse(ReadConfiguration(path)));
            if (previous.id != profile.id) throw std::runtime_error("Conflicting profile identity");
        } catch (...) {
            throw std::runtime_error("The existing profile cannot be safely replaced.");
        }
    }
    const auto temporary = std::filesystem::path(path.native() + std::filesystem::path(".tmp").native());
    const auto content = profile.ToJson().dump();
    if (content.size() > MaxConfigurationBytes)
        throw std::runtime_error("The saved profile exceeds 1 MiB.");
    // Writes are serialized by the application worker. Never delete the old
    // object before replacement; failure leaves the last saved profile intact.
#ifdef _WIN32
    HANDLE file = CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS,
                             FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) throw std::runtime_error("Unable to save the profile.");
    DWORD written = 0;
    const bool success = WriteFile(file, content.data(), static_cast<DWORD>(content.size()), &written, nullptr)
        && written == content.size() && FlushFileBuffers(file);
    CloseHandle(file);
    if (!success || !MoveFileExW(temporary.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
        DeleteFileW(temporary.c_str());
        throw std::runtime_error("Unable to replace the saved profile.");
    }
#else
    const int file = open(temporary.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_NOFOLLOW, 0600);
    if (file < 0) throw std::runtime_error("Unable to save the profile.");
    std::size_t offset = 0;
    while (offset < content.size()) {
        const auto written = write(file, content.data() + offset, content.size() - offset);
        if (written < 0 && errno == EINTR) continue;
        if (written <= 0) break;
        offset += static_cast<std::size_t>(written);
    }
    const bool success = offset == content.size() && fsync(file) == 0;
    close(file);
    if (!success || rename(temporary.c_str(), path.c_str()) != 0) {
        unlink(temporary.c_str());
        throw std::runtime_error("Unable to replace the saved profile.");
    }
#endif
}

void FileProfileRepository::Remove(const std::string &id) {
    std::filesystem::remove(ObjectPath(id));
}

ProfileManager::ProfileManager(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer)
    : repository_(std::move(repository)), importer_(std::move(importer)) {}
void ProfileManager::Load() {
    auto profiles = repository_->Fetch();
    profiles_ = std::move(profiles);
    loaded_ = true;
}
Profile ProfileManager::Import(const std::filesystem::path &path) {
    if (!loaded_) throw std::runtime_error("Load the saved profiles before importing.");
    auto profile = importer_(ReadConfiguration(path), path.stem().u8string());
    if (profile.name.empty()) profile.name = path.stem().u8string();
    ValidateProfileIdentity(profile);
    // An import must not silently replace an existing profile, especially one
    // currently in use. Explicit replacement can be added as a separate action.
    for (const auto &existing : profiles_) {
        if (existing.id == profile.id) throw std::runtime_error("This profile is already imported.");
    }
    repository_->Save(profile);
    profiles_.push_back(profile);
    Sort(profiles_);
    return profile;
}
void ProfileManager::Remove(const std::string &id) {
    Find(id);
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
