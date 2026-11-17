// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "list.h"
#include "theme.h"

namespace Passepartout {
ThemeList::ThemeList(wxWindow *parent, long style)
    : wxDataViewListCtrl(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize,
        style) {
    Theme::Apply(this);
    Bind(wxEVT_SYS_COLOUR_CHANGED, [this](wxSysColourChangedEvent &event) {
        Theme::Apply(this);
        event.Skip();
    });
}
}
