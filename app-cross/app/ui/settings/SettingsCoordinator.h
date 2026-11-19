// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../context/AppContext.h"
#include "SettingsPresentation.h"
#include "SettingsView.h"
#include <wx/simplebook.h>

namespace Passepartout {
class SettingsCoordinator final : public wxDialog {
public:
    SettingsCoordinator(wxWindow *parent, AppContext &context);
private:
    void ReportIssue();
    void SelectSection(SettingsSection section);
    void ShowSection(wxString title, std::function<wxWindow *(wxWindow *)> makePage);
    AppContext &context_;
    SettingsSection section_ = SettingsSection::Preferences;
    wxSimplebook *pages_;
};
}
