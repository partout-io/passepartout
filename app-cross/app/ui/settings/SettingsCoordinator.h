// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../observables/AppContext.h"
#include "SettingsView.h"
#include <wx/simplebook.h>

namespace Passepartout {
class SettingsCoordinator final : public wxDialog {
public:
    SettingsCoordinator(wxWindow *parent, AppContext &context);
private:
    void ReportIssue();
    void SelectSection(SettingsSection section);
    void ShowSection(wxWindow *page, const wxString &title);
    AppContext &context_;
    SettingsSection section_ = SettingsSection::Preferences;
    wxSimplebook *pages_;
};
}
