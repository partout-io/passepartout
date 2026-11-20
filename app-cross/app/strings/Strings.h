// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/string.h>
#include "StringKey.h"

namespace Passepartout {
// Apple resource keys, with the system language and then English as fallback.
wxString Localized(StringKey key);
wxString Localized(StringKey key, const wxString &locale);
}
