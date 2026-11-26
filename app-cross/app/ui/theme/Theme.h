// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>
#include <wx/activityindicator.h>
#include <wx/dataview.h>

namespace Passepartout {
struct Theme {
    static wxIcon AppIcon(wxWindow *window, int size_dip = 0);
    static wxIcon SettingsIcon(wxWindow *window);
    static wxIcon ProfileIcon(wxWindow *window);
    enum class Space { Row, SectionContent, Section, Columns };
    static int Spacing(wxWindow *window, Space space = Space::Section);
    enum class Background { Surface, Content };
    static void Apply(wxWindow *window, Background background = Background::Surface);
    static void SecondaryText(wxWindow *window);
    static void Monospace(wxWindow *window);
    static wxDataViewRenderer *SwitchRenderer(const wxString &on_label, const wxString &off_label);
    static wxActivityIndicator *ProgressView(wxWindow *parent);
    static wxStaticText *EmptyMessage(wxWindow *parent, const wxString &message);
};
}
