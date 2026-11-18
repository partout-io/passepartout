// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ThemeNavigationLink.h"

namespace Passepartout {
ThemeNavigationLink::ThemeNavigationLink(wxWindow *parent, const wxString &title,
    std::function<void()> navigate)
    : wxHyperlinkCtrl(parent, wxID_ANY, title, wxString(), wxDefaultPosition,
        wxDefaultSize, wxHL_ALIGN_LEFT | wxBORDER_NONE) {
    // Internal destinations have neither browser history nor a Copy URL action.
    SetVisitedColour(GetNormalColour());
    Bind(wxEVT_HYPERLINK, [this, navigate = std::move(navigate)](wxHyperlinkEvent &) {
        // Consuming the event suppresses the control's default browser action.
        CallAfter(navigate);
    });
}
}
