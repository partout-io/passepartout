// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileListView.h"
#include "../../strings/Strings.h"
#include "../extensions/AppProfile.h"
#include <algorithm>
#include <wx/numformatter.h>
#ifdef __WXMSW__
#include "../theme/ThemeSwitchRenderer.h"
#endif

namespace Passepartout {
namespace {
class ProfileListStore final : public wxDataViewListStore {
public:
    bool IsEnabledByRow(unsigned row, unsigned column) const override {
        return column != ProfileListView::ToggleColumn || GetItemData(GetItem(row)) != 0;
    }
};
wxString Text(const std::string &value) {
    return wxString::FromUTF8(value);
}
wxString StatusText(Status status) {
    switch (status) {
        case Status::disconnected: return Localized(StringKey::EntitiesTunnelStatusInactive);
        case Status::connecting: return Localized(StringKey::EntitiesTunnelStatusActivating);
        case Status::connected: return Localized(StringKey::EntitiesTunnelStatusActive);
        case Status::disconnecting: return Localized(StringKey::EntitiesTunnelStatusDeactivating);
        default: return Localized(StringKey::GlobalNounsUnknown);
    }
}
wxString TransferText(const AppSnapshot &state, const std::string &id) {
    if (!state.tunnelAvailable) return {};
    for (const auto &tunnel : state.tunnels) {
        if (tunnel.id != id || tunnel.status.value != Status::connected || !tunnel.transfer) continue;
        const auto &transfer = *tunnel.transfer;
        if (transfer.received < 0 || transfer.sent < 0) return {};
        return Text(Passepartout::TransferText(transfer, [](double value, int precision) {
            return wxNumberFormatter::ToString(value, precision, wxNumberFormatter::Style_WithThousandsSep).ToStdString(wxConvUTF8);
        }));
    }
    return {};
}
}
ProfileListView::ProfileListView(wxWindow *parent, TunnelObservable &tunnel,
    std::function<void()> selectionChanged,
    std::function<void(std::vector<std::string>)> remove,
    std::function<void(std::string)> edit)
    : wxPanel(parent), tunnel_(tunnel), selectionChanged_(std::move(selectionChanged)),
      remove_(std::move(remove)), edit_(std::move(edit)) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    search_ = new wxSearchCtrl(this, wxID_ANY);
    search_->ShowCancelButton(true);
    layout->Add(search_, 0, wxEXPAND | wxBOTTOM, Theme::Spacing(this));
    list_ = new ThemeList(this, wxDV_MULTIPLE);
    auto *store = new ProfileListStore;
    list_->AssociateModel(store);
    store->DecRef();
    list_->SetName(Localized(StringKey::GlobalNounsProfiles));
    list_->AppendTextColumn(Localized(StringKey::GlobalNounsName), wxDATAVIEW_CELL_INERT, parent->FromDIP(230));
    list_->AppendTextColumn(Localized(StringKey::GlobalNounsStatus), wxDATAVIEW_CELL_INERT, parent->FromDIP(140));
    list_->AppendTextColumn(wxString(), wxDATAVIEW_CELL_INERT, parent->FromDIP(190));
#ifdef __WXMSW__
    list_->AppendColumn(new wxDataViewColumn(wxString(),
        new ThemeSwitchRenderer(Localized(StringKey::EntitiesTunnelStatusActive),
                                Localized(StringKey::EntitiesTunnelStatusInactive)),
        ToggleColumn, parent->FromDIP(90), wxALIGN_CENTER), "bool");
#else
    list_->AppendToggleColumn(wxString(), wxDATAVIEW_CELL_ACTIVATABLE,
                       parent->FromDIP(90), wxALIGN_CENTER);
#endif
    layout->Add(list_, 1, wxEXPAND);
    SetSizer(layout);
    search_->Bind(wxEVT_TEXT, [this](wxCommandEvent &) {
        RenderRows();
        selectionChanged_();
    });
    list_->Bind(wxEVT_DATAVIEW_SELECTION_CHANGED, [this](wxDataViewEvent &) {
        if (!rendering_) selectionChanged_();
    });
    list_->Bind(wxEVT_DATAVIEW_ITEM_VALUE_CHANGED, &ProfileListView::ToggleProfile, this);
    list_->Bind(wxEVT_DATAVIEW_ITEM_ACTIVATED, [this](wxDataViewEvent &event) {
        if (event.GetColumn() == ProfileListView::ToggleColumn || picking_) return;
        const auto row = list_->ItemToRow(event.GetItem());
        if (row >= 0 && static_cast<std::size_t>(row) < visibleIds_.size()) edit_(visibleIds_[row]);
    });
    list_->Bind(wxEVT_DATAVIEW_ITEM_CONTEXT_MENU, [this](wxDataViewEvent &event) {
        const auto item = event.GetItem();
        if (!item.IsOk()) return;
        if (!list_->IsSelected(item)) {
            list_->UnselectAll();
            list_->Select(item);
        }
        list_->SetFocus();
        ShowContextMenu(wxGetMousePosition());
    });
}
void ProfileListView::Render(const AppSnapshot &state, bool picking) {
    snapshot_ = state;
    picking_ = picking;
    RenderRows();
}
std::vector<std::string> ProfileListView::SelectedIds() const {
    std::vector<std::string> ids;
    wxDataViewItemArray selected;
    list_->GetSelections(selected);
    for (const auto &item : selected) {
        const auto row = list_->ItemToRow(item);
        if (row >= 0 && static_cast<std::size_t>(row) < visibleIds_.size()) ids.push_back(visibleIds_[row]);
    }
    return ids;
}
void ProfileListView::RenderRows() {
    rendering_ = true;
    const auto selected = SelectedIds();
    list_->Freeze();
    const auto query = search_->GetValue().Lower();
    std::vector<std::string> ids;
    for (const auto &profile : snapshot_.profiles) {
        if (query.empty() || Text(profile.name).Lower().Contains(query)) ids.push_back(profile.id);
    }
    const bool rebuild = ids != visibleIds_;
    if (rebuild) {
        list_->DeleteAllItems();
    }
    visibleIds_ = std::move(ids);
    unsigned row = 0;
    for (const auto &profile : snapshot_.profiles) {
        if (!query.empty() && !Text(profile.name).Lower().Contains(query)) continue;
        const auto toggle = TunnelObservable::StateForProfile(snapshot_, profile.id);
        const auto status = snapshot_.tunnelAvailable &&
            snapshot_.tunnelObservationErrors.find(profile.id) == snapshot_.tunnelObservationErrors.end()
            ? StatusText(toggle.status) : wxString();
        const auto transfer = TransferText(snapshot_, profile.id);
        if (rebuild) AppendProfile(Text(profile.name), status, toggle.isOn, toggle.canInteract && !picking_, transfer);
        else UpdateProfile(row, Text(profile.name), status, toggle.isOn, toggle.canInteract && !picking_, transfer);
        ++row;
    }
    if (rebuild) RestoreSelection(selected);
    list_->Thaw();
    rendering_ = false;
}
void ProfileListView::RestoreSelection(const std::vector<std::string> &ids) {
    const bool wasRendering = rendering_;
    rendering_ = true;
    list_->UnselectAll();
    for (std::size_t row = 0; row < visibleIds_.size(); ++row) {
        if (std::find(ids.begin(), ids.end(), visibleIds_[row]) == ids.end()) continue;
        list_->SelectRow(static_cast<unsigned>(row));
    }
    rendering_ = wasRendering;
}
void ProfileListView::ToggleProfile(wxDataViewEvent &event) {
    if (picking_ || rendering_ || event.GetColumn() != ProfileListView::ToggleColumn) return;
    const auto row = list_->ItemToRow(event.GetItem());
    if (row < 0 || static_cast<std::size_t>(row) >= visibleIds_.size()) return;
    tunnel_.SetEnabled(visibleIds_[row], list_->GetToggleValue(row, ProfileListView::ToggleColumn));
    // Restore observed state immediately; the next snapshot supplies completion
    // or failure instead of displaying an optimistic connection as successful.
    snapshot_ = tunnel_.Snapshot();
    RenderRows();
}
bool ProfileListView::HasCollectionFocus() const {
    auto *focus = wxWindow::FindFocus();
    return focus && (focus == list_ || list_->IsDescendant(focus));
}
void ProfileListView::ShowContextMenu(const wxPoint &screenPosition) {
    const auto ids = SelectedIds();
    if (ids.empty()) return;
    wxWindow *collection = list_;
    wxPoint position;
    if (screenPosition != wxDefaultPosition) position = collection->ScreenToClient(screenPosition);
    else position = list_->GetItemRect(list_->GetCurrentItem()).GetBottomLeft();
    wxMenu menu;
    if (ids.size() == 1) {
        menu.Append(wxID_EDIT, Localized(StringKey::GlobalActionsEdit));
        menu.Enable(wxID_EDIT, !picking_ && !snapshot_.foregroundBusy);
    }
    menu.Append(wxID_DELETE, Localized(StringKey::GlobalActionsRemove));
    menu.Enable(wxID_DELETE, !picking_ && ProfileObservable::CanRemove(tunnel_.Snapshot(), ids));
    // Popup menus run a nested event loop: retain the captured IDs even when
    // background snapshots change the visible rows or selection.
    const auto action = collection->GetPopupMenuSelectionFromUser(menu, position);
    if (action == wxID_DELETE) remove_(ids);
    else if (action == wxID_EDIT && ids.size() == 1) edit_(ids.front());
}
void ProfileListView::AppendProfile(const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer) {
    wxVector<wxVariant> values;
    values.push_back(wxVariant(name));
    values.push_back(wxVariant(status));
    values.push_back(wxVariant(transfer));
    values.push_back(wxVariant(isOn));
    list_->AppendItem(values, enabled ? 1 : 0);
}
void ProfileListView::UpdateProfile(unsigned row, const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer) {
    list_->SetItemData(list_->RowToItem(row), enabled ? 1 : 0);
    list_->SetTextValue(name, row, 0);
    list_->SetTextValue(status, row, 1);
    list_->SetToggleValue(isOn, row, ToggleColumn);
    list_->SetTextValue(transfer, row, TransferColumn);
}
}
