// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Presentation.h"
#include <wx/weakref.h>
#ifdef _WIN32
#include "WindowsURLLauncher.h"
#endif

namespace Passepartout {
#ifdef _WIN32
namespace {
// Owned by the requesting view: closing that view cancels the native operation.
// Polling keeps completion/error presentation on wx's UI thread without waiting
// on WinRT or posting callbacks into a view that may already have been destroyed.
class URLLaunch final : public wxWindow {
public:
    URLLaunch(wxWindow *parent, const std::string &url)
        : wxWindow(parent, wxID_ANY), request_(url), timer_(this) {
        Hide();
        Bind(wxEVT_TIMER, [this](wxTimerEvent &) {
            std::optional<bool> result;
            try {
                result = request_.Poll();
            } catch (...) {
                result = false;
            }
            if (!result) return;
            timer_.Stop();
            const wxWeakRef<wxWindow> target(this);
            if (!*result) PresentError(GetParent());
            if (target) target->Destroy();
        });
        timer_.Start(50);
    }
private:
    WindowsURLLauncher request_;
    wxTimer timer_;
};
}
#endif

void PresentError(wxWindow *parent, StringKey message) {
    wxMessageDialog dialog(parent, Localized(message), wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
    dialog.SetOKLabel(Localized(StringKey::GlobalNounsOk));
    dialog.ShowModal();
}

void OpenURL(wxWindow *parent, const std::string &url) {
    try {
        if (url.compare(0, 8, "https://") != 0) {
            PresentError(parent);
            return;
        }
#ifdef _WIN32
        new URLLaunch(parent, url);
#else
        const wxLogNull suppress_native_alert;
        if (!wxLaunchDefaultBrowser(wxString::FromUTF8(url))) PresentError(parent);
#endif
    } catch (...) {
        PresentError(parent);
    }
}
}
