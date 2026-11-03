// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>
#include <wx/activityindicator.h>
#include <wx/dataview.h>

namespace Passepartout {
struct Theme {
    static wxIcon AppIcon(wxWindow *window);
    static int Spacing(wxWindow *window);
    static void Apply(wxWindow *window);
};
wxActivityIndicator *ThemeProgressView(wxWindow *parent);
class ThemeProfileList final : public wxDataViewListCtrl {
public:
    explicit ThemeProfileList(wxWindow *parent);
    void AppendProfile(const wxString &name, const wxString &status, bool isOn, bool enabled);
    void UpdateProfile(unsigned row, const wxString &name, const wxString &status, bool isOn, bool enabled);
    static constexpr unsigned ToggleColumn = 2;
};
wxStaticText *ThemeEmptyMessage(wxWindow *parent, const wxString &message);
}
