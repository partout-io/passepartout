// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>
#include <wx/activityindicator.h>

namespace Passepartout {
struct Theme {
    static wxIcon AppIcon(wxWindow *window, int sizeDIP = 0);
    static wxIcon SettingsIcon(wxWindow *window);
    enum class Space { Row, SectionContent, Section, Columns };
    static int Spacing(wxWindow *window, Space space = Space::Section);
    static void Apply(wxWindow *window);
    static void SecondaryText(wxWindow *window);
    static void Monospace(wxWindow *window);
};
wxActivityIndicator *ThemeProgressView(wxWindow *parent);
wxStaticText *ThemeEmptyMessage(wxWindow *parent, const wxString &message);
}
