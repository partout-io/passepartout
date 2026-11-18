// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../observables/CreditsObservable.h"
#include <wx/wx.h>

namespace Passepartout {
class LicenseView final : public wxPanel {
public:
    LicenseView(wxWindow *parent, CreditsObservable &credits, std::string url, const wxString &title);
private:
    void UpdateContent();
    CreditsObservable &credits_;
    std::string url_;
    wxTextCtrl *content_;
    wxTimer timer_;
};
}
