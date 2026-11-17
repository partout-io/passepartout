// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "file_preferences_repository.h"
#include "atomic_file.h"
#include "profile.h"

namespace Passepartout {
FilePreferencesRepository::FilePreferencesRepository(std::filesystem::path path) : path_(std::move(path)) {
    std::filesystem::create_directories(path_.parent_path());
}
Models::AppPreferences FilePreferencesRepository::Fetch() {
    auto defaults = DefaultPreferences();
    if (!std::filesystem::exists(path_)) return defaults;
    const auto data = nlohmann::json::parse(ReadConfiguration(path_));
    if (!data.is_object()) throw std::runtime_error("Invalid preferences.");
    auto merged = defaults.ToJson();
    merged.update(data);
    auto preferences = Models::AppPreferences::FromJson(merged);
    preferences.cryptoBackend = defaults.cryptoBackend;
    return preferences;
}
void FilePreferencesRepository::Save(const Models::AppPreferences &preferences) {
    WriteAtomicFile(path_, preferences.ToJson().dump());
}
}
