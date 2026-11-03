// SPDX-License-Identifier: GPL-3.0
#pragma once
#include <wx/string.h>

namespace Passepartout {
// Apple resource keys, with the system language and then English as fallback.
wxString Localized(const char *key);
wxString Localized(const char *key, const wxString &locale);
}
