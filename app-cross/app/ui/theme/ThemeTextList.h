// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/panel.h>
#include <string>
#include <vector>

namespace Passepartout {
class ThemeTextList final : public wxPanel {
public:
    ThemeTextList(wxWindow *parent, const wxString &title, const std::vector<std::string> &values);
};
}
