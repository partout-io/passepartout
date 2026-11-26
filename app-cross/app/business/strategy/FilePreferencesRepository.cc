// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../extensions/ModelsExtensions.h"
#include "FilePreferencesRepository.h"

namespace Passepartout {
FilePreferencesRepository::FilePreferencesRepository(std::filesystem::path path) : path_(std::move(path)) {
    std::filesystem::create_directories(path_.parent_path());
}

Models::AppPreferences FilePreferencesRepository::Fetch() {
    auto defaults = Preferences::Defaults();
    if (!std::filesystem::exists(path_)) return defaults;
    const auto data = Partout::Json::Parse(Profiles::ReadConfiguration(path_));
    if (!data.IsObject()) throw std::runtime_error("Invalid preferences.");
    auto merged = defaults.ToJson();
    merged.Merge(data);
    auto preferences = Models::AppPreferences::FromJson(merged);
    preferences.cryptoBackend = defaults.cryptoBackend;
    return preferences;
}

void FilePreferencesRepository::Save(const Models::AppPreferences &preferences) {
    AtomicFile::Write(path_, preferences.ToJson().Encode());
}
}
