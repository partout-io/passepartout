// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "profile_list.h"
#include "../strings/strings.h"
#ifdef __WXMSW__
#include "switch.h"
#endif

namespace Passepartout {
namespace {
class ProfileListStore final : public wxDataViewListStore {
public:
    bool IsEnabledByRow(unsigned row, unsigned column) const override {
        return column != ThemeProfileList::ToggleColumn || GetItemData(GetItem(row)) != 0;
    }
};
}
ThemeProfileList::ThemeProfileList(wxWindow *parent)
    : wxDataViewListCtrl(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxDV_MULTIPLE | wxDV_ROW_LINES) {
    auto *store = new ProfileListStore;
    AssociateModel(store);
    store->DecRef();
    SetName(Localized(StringKey::GlobalNounsProfiles));
    AppendTextColumn(Localized(StringKey::GlobalNounsName), wxDATAVIEW_CELL_INERT, parent->FromDIP(230));
    AppendTextColumn(Localized(StringKey::GlobalNounsStatus), wxDATAVIEW_CELL_INERT, parent->FromDIP(140));
    AppendTextColumn(wxString(), wxDATAVIEW_CELL_INERT, parent->FromDIP(190));
#ifdef __WXMSW__
    AppendColumn(new wxDataViewColumn(wxString(),
        new ThemeSwitchRenderer(Localized(StringKey::EntitiesTunnelStatusActive),
                                Localized(StringKey::EntitiesTunnelStatusInactive)),
        ToggleColumn, parent->FromDIP(90), wxALIGN_CENTER), "bool");
#else
    AppendToggleColumn(wxString(), wxDATAVIEW_CELL_ACTIVATABLE,
                       parent->FromDIP(90), wxALIGN_CENTER);
#endif
}
void ThemeProfileList::AppendProfile(const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer) {
    wxVector<wxVariant> values;
    values.push_back(wxVariant(name));
    values.push_back(wxVariant(status));
    values.push_back(wxVariant(transfer));
    values.push_back(wxVariant(isOn));
    AppendItem(values, enabled ? 1 : 0);
}
void ThemeProfileList::UpdateProfile(unsigned row, const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer) {
    SetItemData(RowToItem(row), enabled ? 1 : 0);
    SetTextValue(name, row, 0);
    SetTextValue(status, row, 1);
    SetToggleValue(isOn, row, ToggleColumn);
    SetTextValue(transfer, row, TransferColumn);
}
}
