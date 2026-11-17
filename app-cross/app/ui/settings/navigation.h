// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>
#include <functional>

namespace Passepartout {
using SettingsNavigation = std::function<void(wxString, std::function<wxWindow *(wxWindow *)>)>;
}
