// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <filesystem>
#include <wx/string.h>

namespace Passepartout::Paths {
std::filesystem::path FromString(const wxString &value);
}
