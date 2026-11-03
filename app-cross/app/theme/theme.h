// SPDX-License-Identifier: GPL-3.0
#pragma once
#include <wx/wx.h>
#include <wx/activityindicator.h>
#include <wx/listctrl.h>

namespace Passepartout {
struct Theme {
    static int Spacing(wxWindow *window);
    static void Apply(wxWindow *window);
};
wxActivityIndicator *ThemeProgressView(wxWindow *parent);
wxListCtrl *ThemeList(wxWindow *parent);
wxStaticText *ThemeEmptyMessage(wxWindow *parent, const wxString &message);
}
