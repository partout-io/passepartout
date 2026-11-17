// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "list.h"
#include "theme.h"
#include <algorithm>

namespace Passepartout {
ThemeList::ThemeList(wxWindow *parent, long style)
    : wxDataViewListCtrl(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize,
        style | wxDV_ROW_LINES | wxBORDER_NONE) {
    Theme::Apply(this);
    SetRowHeight(RowHeight());
    Bind(wxEVT_SYS_COLOUR_CHANGED, [this](wxSysColourChangedEvent &event) {
        Theme::Apply(this);
        event.Skip();
    });
    Bind(wxEVT_DPI_CHANGED, [this](wxDPIChangedEvent &event) {
        SetRowHeight(RowHeight());
        event.Skip();
    });
}
int ThemeList::RowHeight() const {
    return std::max(FromDIP(36), GetCharHeight() + FromDIP(16));
}
}
