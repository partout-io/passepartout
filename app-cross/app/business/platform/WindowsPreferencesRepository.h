// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/PreferencesRepository.h"
#include <string>

namespace Passepartout::Windows {
class PreferencesRepository final : public Passepartout::PreferencesRepository {
public:
    explicit PreferencesRepository(std::wstring key);
    Models::AppPreferences Fetch() override;
    void Save(const Models::AppPreferences &preferences) override;
private:
    const std::wstring key_;
};
}
