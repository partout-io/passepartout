// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../extensions/Models+Business.h"
#include "FilePreferencesRepository.h"

namespace Passepartout {
FilePreferencesRepository::FilePreferencesRepository(std::filesystem::path path) : path_(std::move(path)) {
    std::filesystem::create_directories(path_.parent_path());
}

Models::AppPreferences FilePreferencesRepository::Fetch() {
    if (!std::filesystem::exists(path_)) return Preferences::Defaults();
    return Preferences::FromJson(Partout::Json::Parse(Profiles::ReadConfiguration(path_)));
}

void FilePreferencesRepository::Save(const Models::AppPreferences &preferences) {
    AtomicFile::Write(path_, preferences.ToJson().Encode());
}
}
