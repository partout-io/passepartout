// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "FilePath.h"
#include "../../business/extensions/Paths.h"

namespace Passepartout {
std::filesystem::path Paths::FromString(const wxString &value) {
    return FromUtf8(value.ToStdString(wxConvUTF8));
}
}
