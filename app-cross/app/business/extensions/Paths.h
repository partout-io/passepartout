// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <filesystem>
#include <string>

namespace Passepartout::Paths {
std::filesystem::path FromUtf8(const std::string &value);
}
