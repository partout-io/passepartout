// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../context/app_context.h"
#include "navigation.h"
#include <wx/simplebook.h>

namespace Passepartout {
class SettingsView final : public wxDialog {
public:
    SettingsView(wxWindow *parent, AppContext &context, bool showVersion = false);
private:
    void Push(wxString title, std::function<wxWindow *(wxWindow *)> makePage);
    void Back();
    wxSimplebook *pages_;
    wxButton *back_;
    std::vector<wxString> titles_;
};
}
