// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>

namespace Passepartout {
class ThemeLongContent final : public wxPanel {
public:
    ThemeLongContent(wxWindow *parent, const wxString &title, const wxString &content);
};
}
