// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../strings/Strings.h"
#include <wx/wx.h>

namespace Passepartout {
void PresentError(wxWindow *parent, StringKey message = StringKey::ErrorsAppOther);
void OpenURL(wxWindow *parent, const std::string &url);
}
