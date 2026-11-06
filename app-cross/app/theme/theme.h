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
    void AppendProfile(const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer);
    void UpdateProfile(unsigned row, const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer);
    static constexpr unsigned TransferColumn = 2;
    static constexpr unsigned ToggleColumn = 3;
};
wxStaticText *ThemeEmptyMessage(wxWindow *parent, const wxString &message);
}
