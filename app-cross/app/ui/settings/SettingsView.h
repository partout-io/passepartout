// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/panel.h>
#include <functional>

namespace Passepartout {
enum class SettingsSection { Preferences = 1, Links, Credits, FAQ, Diagnostics, Update };
class SettingsView final : public wxPanel {
public:
    SettingsView(wxWindow *parent, const wxString &updateTitle,
        SettingsSection initial, std::function<void(SettingsSection)> selected);
private:
    unsigned selectedRow_ = 0;
};
}
