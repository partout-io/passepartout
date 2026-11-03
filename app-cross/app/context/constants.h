// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <string>

namespace Passepartout {
// Frontend-specific defaults, matching AndroidConstants' responsibility.
// Shared product values belong to the generated AppConstants model instead.
struct CrossConstants {
    struct Tags {
        std::string app = "Passepartout";
    } tags;
    struct Storage {
        std::string demoPrefix = "demo-";
    } storage;
    struct Tunnel {
        std::wstring profilePrefix = L"Passepartout ";
    } tunnel;
    struct CommandLine {
        std::string demoArgument = "--demo";
    } commandLine;
};
inline const CrossConstants defaultCrossConstants{};
}
