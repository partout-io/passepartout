// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "profiles.h"
#include <algorithm>
#include <cerrno>
#include <cstdio>
#include <fstream>
#include <stdexcept>
#include <set>
#include <limits>
#include <locale>
#include <codecvt>
#include <random>
#include <sstream>
#include <iomanip>
#include <cmath>
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
    auto upper = id;
    std::transform(upper.begin(), upper.end(), upper.begin(), [](unsigned char c) {
        return static_cast<char>(std::toupper(c));
    });
    if (upper == "CON" || upper == "PRN" || upper == "AUX" || upper == "NUL" ||
        (upper.size() == 4 && (upper.substr(0, 3) == "COM" || upper.substr(0, 3) == "LPT") &&
         upper[3] >= '0' && upper[3] <= '9')) return false;
    return !id.empty() && id.size() <= 128 &&
        std::all_of(id.begin(), id.end(), [](unsigned char c) {
            return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') || c == '-' || c == '_';
        });
}
std::wstring LowerName(const std::string &name) {
#ifdef _WIN32
    if (name.empty()) return {};
    const int wideSize = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, name.data(), static_cast<int>(name.size()), nullptr, 0);
    if (!wideSize) throw std::runtime_error("Invalid UTF-8 profile name.");
    std::wstring wide(wideSize, L'\0');
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, name.data(), static_cast<int>(name.size()), wide.data(), wideSize);
#else
    std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
    auto wide = converter.from_bytes(name);
#endif
#ifdef _WIN32
    if (wide.empty()) return wide;
    const int size = LCMapStringEx(LOCALE_NAME_INVARIANT, LCMAP_LOWERCASE,
        wide.data(), static_cast<int>(wide.size()), nullptr, 0, nullptr, nullptr, 0);
    if (!size) throw std::runtime_error("Unable to order profile names.");
    std::wstring lower(size, L'\0');
    LCMapStringEx(LOCALE_NAME_INVARIANT, LCMAP_LOWERCASE,
        wide.data(), static_cast<int>(wide.size()), lower.data(), size, nullptr, nullptr, 0);
    return lower;
#else
    static const std::locale locale("");
    const auto &facet = std::use_facet<std::ctype<wchar_t>>(locale);
    if (!wide.empty()) facet.tolower(wide.data(), wide.data() + wide.size());
    return wide;
#endif
}
double LastUpdate(const Profile &profile) {
    if (profile.userInfo && profile.userInfo->is_object()) {
        const auto value = profile.userInfo->find("lastUpdate");
        if (value != profile.userInfo->end()) {
            if (value->is_number()) return value->get<double>();
            if (value->is_string()) {
                try {
                    std::size_t length;
                    const auto text = value->get<std::string>();
                    const auto number = std::stod(text, &length);
                    if (length == text.size() && std::isfinite(number)) return number;
                } catch (...) {}
            }
        }
    }
    return -std::numeric_limits<double>::infinity();
}
void Sort(std::vector<Profile> &profiles) {
    std::sort(profiles.begin(), profiles.end(), [](const auto &a, const auto &b) {
        const auto left = LowerName(a.name);
        const auto right = LowerName(b.name);
        if (left != right) return left < right;
        const auto leftDate = LastUpdate(a);
        const auto rightDate = LastUpdate(b);
        if (leftDate != rightDate) return leftDate > rightDate;
        return a.id < b.id;
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
    : root_(std::move(directory)), directory_(root_ / "objects") {
    std::filesystem::create_directories(directory_);
    std::filesystem::create_directories(root_ / "tmp");
#ifndef _WIN32
    std::filesystem::permissions(directory_.parent_path(), std::filesystem::perms::owner_all);
    std::filesystem::permissions(directory_, std::filesystem::perms::owner_all);
    std::filesystem::permissions(root_ / "tmp", std::filesystem::perms::owner_all);
#endif
    Fetch();
}

std::filesystem::path FileProfileRepository::ObjectPath(const std::string &id) const {
    if (!IsSafeId(id)) throw std::runtime_error("Invalid profile identifier.");
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
            auto profile = Profile::FromJson(nlohmann::json::parse(ReadConfiguration(entry.path())));
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
    Sort(profiles);
    return profiles;
}

void FileProfileRepository::PersistIndex(const std::vector<Profile> &profiles) {
    auto entries = nlohmann::json::array();
    for (const auto &profile : profiles) {
        nlohmann::json entry = {{"id", profile.id}, {"name", profile.name}};
        if (profile.userInfo && profile.userInfo->is_object()) {
            for (const auto *key : {"lastUpdate", "fingerprint"}) {
                const auto value = profile.userInfo->find(key);
                if (value == profile.userInfo->end() || value->is_null()) continue;
                if (std::string(key) == "fingerprint") {
                    if (value->is_primitive()) entry[key] = value->is_string() ? value->get<std::string>() : value->dump();
                } else {
                    entry[key] = *value;
                }
            }
        }
        entries.push_back(std::move(entry));
    }
    WriteAtomically(root_ / "index.json", nlohmann::json{{"version", 1}, {"profiles", entries}}.dump());
}

std::vector<Profile> FileProfileRepository::Fetch() {
    auto objects = ReadObjects();
    std::vector<std::string> orderedIds;
    bool rebuild = false;
    try {
        const auto index = nlohmann::json::parse(ReadConfiguration(root_ / "index.json"));
        if (index.at("version") != 1 || !index.at("profiles").is_array()) throw std::runtime_error("Invalid index");
        std::set<std::string> seen;
        for (const auto &entry : index.at("profiles")) {
            auto id = entry.at("id").get<std::string>();
            entry.at("name").get<std::string>();
            if (!IsSafeId(id) || !seen.insert(id).second) throw std::runtime_error("Invalid index identity");
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
            const auto previous = Profile::FromJson(nlohmann::json::parse(ReadConfiguration(path)));
            if (previous.id != profile.id) throw std::runtime_error("Conflicting profile identity");
        } catch (...) {
            throw std::runtime_error("The existing profile cannot be safely replaced.");
        }
    }
    const auto content = profile.ToJson().dump();
    if (content.size() > MaxConfigurationBytes)
        throw std::runtime_error("The saved profile exceeds 1 MiB.");
    WriteAtomically(path, content);
    profiles.erase(std::remove_if(profiles.begin(), profiles.end(), [&](const auto &p) { return p.id == profile.id; }), profiles.end());
    profiles.push_back(profile);
    Sort(profiles);
    PersistIndex(profiles);
}

void FileProfileRepository::WriteAtomically(const std::filesystem::path &path, const std::string &content) {
    std::random_device random;
    std::ostringstream uuid;
    uuid << std::hex << std::setfill('0');
    for (int i = 0; i < 16; ++i) {
        if (i == 4 || i == 6 || i == 8 || i == 10) uuid << '-';
        auto byte = random() & 0xff;
        if (i == 6) byte = (byte & 0x0f) | 0x40;
        if (i == 8) byte = (byte & 0x3f) | 0x80;
        uuid << std::setw(2) << byte;
    }
    const auto temporary = root_ / "tmp" / (uuid.str() + ".tmp");
    // Writes are serialized by the application worker. Never delete the old
    // object before replacement; failure leaves the last saved profile intact.
#ifdef _WIN32
    HANDLE file = CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW,
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
    const int file = open(temporary.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
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
    auto profiles = ReadObjects();
    std::filesystem::remove(ObjectPath(id));
    profiles.erase(std::remove_if(profiles.begin(), profiles.end(), [&](const auto &p) { return p.id == id; }), profiles.end());
    PersistIndex(profiles);
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
