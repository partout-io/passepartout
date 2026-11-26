// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <string>

namespace Passepartout {
// Frontend-specific defaults. Shared product values belong to
// the generated AppConstants model instead.
struct CrossConstantsType {
    struct App final {
        std::string name = "Passepartout";
        std::string version_number = PASSEPARTOUT_APP_VERSION;
        int build_number = PASSEPARTOUT_APP_BUILD;
    } app;
    struct Storage {
        std::string preferences_file = "preferences.json";
        std::wstring preferences_key = L"AppPreferences";
    } storage;
    struct Tunnel {
        std::string server_uri = "https://passepartout.profile";
    } tunnel;
    struct CommandLine {
        std::string demo_argument = "--demo";
    } command_line;
};
inline const CrossConstantsType CrossConstants{};
}
