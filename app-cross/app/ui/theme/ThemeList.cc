// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ThemeList.h"
#include "Theme.h"

namespace Passepartout {
ThemeList::ThemeList(wxWindow *parent, long style)
    : wxDataViewListCtrl(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize,
        style) {
    Theme::Apply(this, Theme::Background::Content);
}
}
