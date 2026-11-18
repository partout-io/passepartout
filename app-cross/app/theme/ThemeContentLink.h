// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/hyperlink.h>
#include <functional>

namespace Passepartout {
// Activates an application destination. The coordinator owns presentation.
class ThemeContentLink final : public wxHyperlinkCtrl {
public:
    ThemeContentLink(wxWindow *parent, const wxString &title, std::function<void()> present);
};
}
