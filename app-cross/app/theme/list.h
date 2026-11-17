// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/dataview.h>

namespace Passepartout {
class ThemeList : public wxDataViewListCtrl {
public:
    explicit ThemeList(wxWindow *parent, long style = 0);
    int RowHeight() const;
};
}
