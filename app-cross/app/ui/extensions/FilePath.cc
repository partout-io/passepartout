// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "FilePath.h"

namespace Passepartout {
std::filesystem::path Paths::FromString(const wxString &value) {
    return std::filesystem::u8path(value.ToStdString(wxConvUTF8));
}
}
