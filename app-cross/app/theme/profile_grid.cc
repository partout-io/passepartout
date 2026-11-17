// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "profile_grid.h"
#include "theme.h"
#include "../strings/strings.h"
#include <wx/imaglist.h>

namespace Passepartout {
ThemeProfileGrid::ThemeProfileGrid(wxWindow *parent)
    : wxListCtrl(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_ICON | wxLC_AUTOARRANGE) {
    SetName(Localized(StringKey::GlobalNounsProfiles));
    const auto icon = Theme::AppIcon(this, 32);
    if (icon.IsOk()) {
        auto *images = new wxImageList(icon.GetWidth(), icon.GetHeight());
        images->Add(icon);
        AssignImageList(images, wxIMAGE_LIST_NORMAL);
    }
}
void ThemeProfileGrid::AppendProfile(const wxString &name, const wxString &status, const wxString &transfer) {
    const auto row = InsertItem(GetItemCount(), name, 0);
    UpdateProfile(row, name, status, transfer);
}
void ThemeProfileGrid::UpdateProfile(long row, const wxString &name, const wxString &status, const wxString &transfer) {
    wxString text = name;
    if (!status.empty()) text += "\n" + status;
    if (!transfer.empty()) text += "\n" + transfer;
    SetItemText(row, text);
}
}
