// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileListView.h"
#include "../../strings/Strings.h"
#include "../extensions/Models+UI.h"
#include <algorithm>
#include <wx/numformatter.h>
#include "../theme/Theme.h"

namespace {
class ProfileListStore final : public wxDataViewListStore {
public:
    bool IsEnabledByRow(unsigned row, unsigned column) const override {
        return column != Passepartout::ProfileListView::ToggleColumn || GetItemData(GetItem(row)) != 0;
    }
};
wxString Text(const std::string &value) {
    return wxString::FromUTF8(value);
}

wxString StatusText(Passepartout::Status status) {
    switch (status) {
        case Passepartout::Status::disconnected: return Passepartout::Localized(Passepartout::StringKey::EntitiesTunnelStatusInactive);
        case Passepartout::Status::connecting: return Passepartout::Localized(Passepartout::StringKey::EntitiesTunnelStatusActivating);
        case Passepartout::Status::connected: return Passepartout::Localized(Passepartout::StringKey::EntitiesTunnelStatusActive);
        case Passepartout::Status::disconnecting: return Passepartout::Localized(Passepartout::StringKey::EntitiesTunnelStatusDeactivating);
        default: return Passepartout::Localized(Passepartout::StringKey::GlobalNounsUnknown);
    }
}

wxString TransferText(const Passepartout::TunnelObservable::State &state, const std::string &id) {
    if (!state.available) return {};
    for (const auto &tunnel : state.tunnels) {
        if (tunnel.id != id || tunnel.status.value != Passepartout::Status::connected || !tunnel.transfer) continue;
        const auto &transfer = *tunnel.transfer;
        if (transfer.received < 0 || transfer.sent < 0) return {};
        return Text(Passepartout::Profiles::TransferText(transfer, [](double value, int precision) {
            return wxNumberFormatter::ToString(value, precision, wxNumberFormatter::Style_WithThousandsSep).ToStdString(wxConvUTF8);
        }));
    }
    return {};
}
}

using Passepartout::ProfileListView;

ProfileListView::ProfileListView(wxWindow *parent, TunnelObservable &tunnel,
    std::function<void()> selection_changed,
    std::function<void(std::vector<std::string>)> remove,
    std::function<void(std::string)> edit)
    : wxPanel(parent), tunnel_(tunnel), selection_changed_(std::move(selection_changed)),
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
    list_->AppendColumn(
        new wxDataViewColumn(
            wxString(),
            Theme::SwitchRenderer(
                Localized(StringKey::EntitiesTunnelStatusActive),
                Localized(StringKey::EntitiesTunnelStatusInactive)
            ),
            ToggleColumn, parent->FromDIP(90), wxALIGN_CENTER
        ),
        "bool"
    );
    layout->Add(list_, 1, wxEXPAND);
    SetSizer(layout);
    search_->Bind(wxEVT_TEXT, [this](wxCommandEvent &) {
        RenderRows();
        selection_changed_();
    });
    list_->Bind(wxEVT_DATAVIEW_SELECTION_CHANGED, [this](wxDataViewEvent &) {
        if (!rendering_) selection_changed_();
    });
    list_->Bind(wxEVT_DATAVIEW_ITEM_VALUE_CHANGED, &ProfileListView::ToggleProfile, this);
    list_->Bind(wxEVT_DATAVIEW_ITEM_ACTIVATED, [this](wxDataViewEvent &event) {
        if (event.GetColumn() == ProfileListView::ToggleColumn || picking_) return;
        const auto row = list_->ItemToRow(event.GetItem());
        if (row >= 0 && static_cast<std::size_t>(row) < visible_ids_.size()) edit_(visible_ids_[row]);
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

void ProfileListView::Render(const ProfileObservable::State &profiles, const TunnelObservable::State &tunnel,
                             const Worker::Activity &activity, bool picking
) {
    profiles_ = profiles;
    tunnels_ = tunnel;
    activity_ = activity;
    picking_ = picking;
    RenderRows();
}

std::vector<std::string> ProfileListView::SelectedIds() const {
    std::vector<std::string> ids;
    wxDataViewItemArray selected;
    list_->GetSelections(selected);
    for (const auto &item : selected) {
        const auto row = list_->ItemToRow(item);
        if (row >= 0 && static_cast<std::size_t>(row) < visible_ids_.size()) ids.push_back(visible_ids_[row]);
    }
    return ids;
}

void ProfileListView::RenderRows() {
    rendering_ = true;
    const auto selected = SelectedIds();
    list_->Freeze();
    const auto query = search_->GetValue().Lower();
    std::vector<std::string> ids;
    for (const auto &profile : profiles_.profiles) {
        if (query.empty() || Text(profile.name).Lower().Contains(query)) ids.push_back(profile.id);
    }
    const bool rebuild = ids != visible_ids_;
    if (rebuild) {
        list_->DeleteAllItems();
    }
    visible_ids_ = std::move(ids);
    unsigned row = 0;
    for (const auto &profile : profiles_.profiles) {
        if (!query.empty() && !Text(profile.name).Lower().Contains(query)) continue;
        const auto toggle = TunnelObservable::StateForProfile(tunnels_, profile.id);
        const auto status = tunnels_.available &&
            tunnels_.observation_errors.find(profile.id) == tunnels_.observation_errors.end()
            ? StatusText(toggle.status) : wxString();
        const auto transfer = TransferText(tunnels_, profile.id);
        if (rebuild) AppendProfile(Text(profile.name), status, toggle.is_on, toggle.can_interact && !picking_, transfer);
        else UpdateProfile(row, Text(profile.name), status, toggle.is_on, toggle.can_interact && !picking_, transfer);
        ++row;
    }
    if (rebuild) RestoreSelection(selected);
    list_->Thaw();
    rendering_ = false;
}

void ProfileListView::RestoreSelection(const std::vector<std::string> &ids) {
    const bool was_rendering = rendering_;
    rendering_ = true;
    list_->UnselectAll();
    for (std::size_t row = 0; row < visible_ids_.size(); ++row) {
        if (std::find(ids.begin(), ids.end(), visible_ids_[row]) == ids.end()) continue;
        list_->SelectRow(static_cast<unsigned>(row));
    }
    rendering_ = was_rendering;
}

void ProfileListView::ToggleProfile(wxDataViewEvent &event) {
    if (picking_ || rendering_ || event.GetColumn() != ProfileListView::ToggleColumn) return;
    const auto row = list_->ItemToRow(event.GetItem());
    if (row < 0 || static_cast<std::size_t>(row) >= visible_ids_.size()) return;
    tunnel_.SetEnabled(visible_ids_[row], list_->GetToggleValue(row, ProfileListView::ToggleColumn));
    // Restore observed state immediately; the next snapshot supplies completion
    // or failure instead of displaying an optimistic connection as successful.
    tunnels_ = tunnel_.Snapshot();
    activity_ = tunnels_.activity;
    RenderRows();
}

bool ProfileListView::HasCollectionFocus() const {
    auto *focus = wxWindow::FindFocus();
    return focus && (focus == list_ || list_->IsDescendant(focus));
}

void ProfileListView::ShowContextMenu(const wxPoint &screen_position) {
    const auto ids = SelectedIds();
    if (ids.empty()) return;
    wxWindow *collection = list_;
    wxPoint position;
    if (screen_position != wxDefaultPosition) position = collection->ScreenToClient(screen_position);
    else position = list_->GetItemRect(list_->GetCurrentItem()).GetBottomLeft();
    wxMenu menu;
    if (ids.size() == 1) {
        menu.Append(wxID_EDIT, Localized(StringKey::GlobalActionsEdit));
        menu.Enable(wxID_EDIT, !picking_ && !activity_.foreground);
    }
    menu.Append(wxID_DELETE, Localized(StringKey::GlobalActionsRemove));
    menu.Enable(wxID_DELETE, !picking_ && ProfileObservable::CanRemove(profiles_, ids) && !tunnels_.pending_profile && !activity_.foreground);
    // Popup menus run a nested event loop: retain the captured IDs even when
    // background snapshots change the visible rows or selection.
    const auto action = collection->GetPopupMenuSelectionFromUser(menu, position);
    if (action == wxID_DELETE) remove_(ids);
    else if (action == wxID_EDIT && ids.size() == 1) edit_(ids.front());
}

void ProfileListView::AppendProfile(const wxString &name, const wxString &status, bool is_on, bool enabled, const wxString &transfer) {
    wxVector<wxVariant> values;
    values.push_back(wxVariant(name));
    values.push_back(wxVariant(status));
    values.push_back(wxVariant(transfer));
    values.push_back(wxVariant(is_on));
    list_->AppendItem(values, enabled ? 1 : 0);
}

void ProfileListView::UpdateProfile(unsigned row, const wxString &name, const wxString &status, bool is_on, bool enabled, const wxString &transfer) {
    list_->SetItemData(list_->RowToItem(row), enabled ? 1 : 0);
    list_->SetTextValue(name, row, 0);
    list_->SetTextValue(status, row, 1);
    list_->SetToggleValue(is_on, row, ToggleColumn);
    list_->SetTextValue(transfer, row, TransferColumn);
}
