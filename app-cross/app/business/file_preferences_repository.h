// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "preferences_repository.h"
#include <filesystem>

namespace Passepartout {
class FilePreferencesRepository final : public PreferencesRepository {
public:
    explicit FilePreferencesRepository(std::filesystem::path path);
    Models::AppPreferences Fetch() override;
    void Save(const Models::AppPreferences &preferences) override;
private:
    std::filesystem::path path_;
};
}
