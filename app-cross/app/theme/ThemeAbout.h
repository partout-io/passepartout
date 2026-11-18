// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>

namespace Passepartout {
struct ThemeAbout {
    static void Show(wxWindow *parent, const wxString &name,
        const wxString &version, const wxString &developer);
};
}
