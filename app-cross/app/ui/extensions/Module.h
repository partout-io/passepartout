// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <partout/models/TaggedModule.h>
#include <wx/string.h>

namespace Passepartout::Modules {
wxString Title(const Partout::Models::TaggedModule &module);
}
