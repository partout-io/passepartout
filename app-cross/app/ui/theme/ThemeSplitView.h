// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/splitter.h>
#include <wx/panel.h>

namespace Passepartout {
class ThemeSplitView final : public wxSplitterWindow {
public:
    explicit ThemeSplitView(wxWindow *parent);
    wxPanel *Sidebar() const { return sidebar_; }
    wxPanel *Detail() const { return detail_; }
    int InitializePanes();
private:
    wxPanel *sidebar_;
    wxPanel *detail_;
};
}
