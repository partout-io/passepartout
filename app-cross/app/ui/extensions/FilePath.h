// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <filesystem>
#include <wx/string.h>

namespace Passepartout {
std::filesystem::path FilePath(const wxString &value);
}
