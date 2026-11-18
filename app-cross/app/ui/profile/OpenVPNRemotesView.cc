// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "OpenVPNRemotesView.h"
#include "../../theme/ThemeList.h"
#include "../../theme/Theme.h"
#include "../../strings/Strings.h"
#include <wx/clipbrd.h>
#include <wx/dataobj.h>
#include <algorithm>

namespace Passepartout {
OpenVPNRemotesView::OpenVPNRemotesView(wxWindow *parent, const std::vector<std::string> &endpoints)
    : wxPanel(parent) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    auto *list = new ThemeList(this, wxDV_NO_HEADER);
    list->SetName(Localized(StringKey::ModulesOpenvpnRemotes));
    list->AppendTextColumn(Localized(StringKey::GlobalNounsEndpoint), wxDATAVIEW_CELL_INERT);
    for (const auto &endpoint : endpoints) {
        wxVector<wxVariant> row;
        row.push_back(wxVariant(wxString::FromUTF8(endpoint)));
        list->AppendItem(row);
    }
    list->Bind(wxEVT_SIZE, [list](wxSizeEvent &event) {
        list->GetColumn(0)->SetWidth(std::max(1, list->GetClientSize().x));
        event.Skip();
    });
    const auto copy = [list] {
        const auto row = list->GetSelectedRow();
        if (row == wxNOT_FOUND || !wxTheClipboard->Open()) return;
        wxTheClipboard->SetData(new wxTextDataObject(list->GetTextValue(row, 0)));
        wxTheClipboard->Close();
    };
    list->Bind(wxEVT_CHAR_HOOK, [copy](wxKeyEvent &event) {
        if (event.ControlDown() && event.GetKeyCode() == 'C') copy();
        else event.Skip();
    });
    list->Bind(wxEVT_DATAVIEW_ITEM_CONTEXT_MENU, [list, copy](wxDataViewEvent &event) {
        if (!event.GetItem().IsOk()) return;
        list->Select(event.GetItem());
        wxMenu menu;
        menu.Append(wxID_COPY, wxGetStockLabel(wxID_COPY));
        if (list->GetPopupMenuSelectionFromUser(menu) == wxID_COPY) copy();
    });
    layout->Add(list, 1, wxEXPAND | wxALL, Theme::Spacing(this));
    SetSizer(layout);
}
}
