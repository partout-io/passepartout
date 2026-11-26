// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Presentation.h"

#ifdef _WIN32
#include "WindowsURLLauncher.h"
#endif

void Passepartout::UseSystemAppearance(wxApp &app) {
#ifdef __WXMSW__
    // Windows needs an explicit opt-in; other ports follow the native theme.
    app.SetAppearance(wxApp::Appearance::System);
#else
    wxUnusedVar(app);
#endif
}

void Passepartout::PresentError(wxWindow *parent, StringKey message) {
    wxMessageDialog dialog(parent, Localized(message), wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
    dialog.SetOKLabel(Localized(StringKey::GlobalNounsOk));
    dialog.ShowModal();
}

void Passepartout::OpenURL(wxWindow *parent, const std::string &url) {
    try {
        if (url.compare(0, 8, "https://") != 0) {
            PresentError(parent);
            return;
        }
#ifdef _WIN32
        new Windows::URLLauncher(parent, url, [](wxWindow *owner) {
            PresentError(owner);
        });
#else
        const wxLogNull suppress_native_alert;
        if (!wxLaunchDefaultBrowser(wxString::FromUTF8(url))) PresentError(parent);
#endif
    } catch (...) {
        PresentError(parent);
    }
}
