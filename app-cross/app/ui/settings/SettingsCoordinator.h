// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../context/AppContext.h"
#include "SettingsNavigation.h"
#include "SettingsView.h"
#include <wx/simplebook.h>

namespace Passepartout {
class SettingsCoordinator final : public wxDialog {
public:
    SettingsCoordinator(wxWindow *parent, AppContext &context, bool showVersion = false);
private:
    void SelectSection(SettingsSection section);
    void Push(wxString title, std::function<wxWindow *(wxWindow *)> makePage);
    void Back();
    void RefreshNavigation();
    AppContext &context_;
    SettingsSection section_ = SettingsSection::Preferences;
    wxSimplebook *pages_;
    wxStaticText *heading_;
    wxButton *back_;
    std::vector<wxString> titles_;
};
}
