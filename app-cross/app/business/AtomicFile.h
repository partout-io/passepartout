// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <filesystem>
#include <string>

namespace Passepartout {
void WriteAtomicFile(const std::filesystem::path &path, const std::string &content);
}
