// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/listctrl.h>

namespace Passepartout {
class ThemeProfileGrid final : public wxListCtrl {
public:
    explicit ThemeProfileGrid(wxWindow *parent);
    void AppendProfile(const wxString &name, const wxString &status, const wxString &transfer);
    void UpdateProfile(long row, const wxString &name, const wxString &status, const wxString &transfer);
};
}
