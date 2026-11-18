// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ThemeAbout.h"
#include "Theme.h"
#include <wx/aboutdlg.h>

namespace Passepartout {
void ThemeAbout::Show(wxWindow *parent, const wxString &name,
    const wxString &version, const wxString &developer) {
    wxAboutDialogInfo info;
    info.SetName(name);
    info.SetVersion(version);
    info.SetIcon(Theme::AppIcon(parent, 64));
    info.AddDeveloper(developer);
    wxAboutBox(info, parent);
}
}
