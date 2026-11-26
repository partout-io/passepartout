// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <string>

namespace Passepartout {
// Frontend-specific defaults, matching AndroidConstants' responsibility.
// Shared product values belong to the generated AppConstants model instead.
struct CrossConstantsType {
    struct Tags {
        std::string app = "Passepartout";
    } tags;
    struct Storage {
        std::string demo_prefix = "demo-";
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
