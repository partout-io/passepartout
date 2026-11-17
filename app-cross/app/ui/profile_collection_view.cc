// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "profile_collection_view.h"
#include "../strings/strings.h"
#include "extensions/app_profile.h"
#include <algorithm>
#include <wx/numformatter.h>

namespace Passepartout {
namespace {
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
ProfileCollectionView::ProfileCollectionView(wxWindow *parent, TunnelObservable &tunnel,
    std::function<void()> selectionChanged,
    std::function<void(std::vector<std::string>)> remove,
    std::function<void(std::string)> edit)
    : wxPanel(parent), tunnel_(tunnel), selectionChanged_(std::move(selectionChanged)),
      remove_(std::move(remove)), edit_(std::move(edit)) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    search_ = new wxSearchCtrl(this, wxID_ANY);
    search_->ShowCancelButton(true);
    layout->Add(search_, 0, wxEXPAND | wxBOTTOM, Theme::Spacing(this));
    auto *choice = new wxChoice(this, wxID_ANY);
    choice->Append(Localized(StringKey::AndroidProfilesLayoutListContentDescription));
    choice->Append(Localized(StringKey::AndroidProfilesLayoutGridContentDescription));
    choice->SetSelection(0);
    layout->Add(choice, 0, wxBOTTOM, Theme::Spacing(this));
    layouts_ = new wxSimplebook(this);
    list_ = new ThemeProfileList(layouts_);
    grid_ = new ThemeProfileGrid(layouts_);
    layouts_->AddPage(list_, wxString(), true);
    layouts_->AddPage(grid_, wxString());
    layout->Add(layouts_, 1, wxEXPAND);
    gridToggle_ = new wxCheckBox(this, wxID_ANY, Localized(StringKey::GlobalNounsEnabled));
    gridToggle_->Hide();
    layout->Add(gridToggle_, 0, wxTOP, Theme::Spacing(this));
    SetSizer(layout);
    choice->Bind(wxEVT_CHOICE, [this, choice](wxCommandEvent &) {
        const auto selected = SelectedIds();
        gridLayout_ = choice->GetSelection() == 1;
        layouts_->SetSelection(gridLayout_ ? 1 : 0);
        gridToggle_->Show(gridLayout_);
        RestoreSelection(selected);
        UpdateGridToggle();
        Layout();
    });
    grid_->Bind(wxEVT_LIST_ITEM_SELECTED, [this](wxListEvent &) {
        if (rendering_) return;
        UpdateGridToggle();
        selectionChanged_();
    });
    grid_->Bind(wxEVT_LIST_ITEM_DESELECTED, [this](wxListEvent &) {
        if (rendering_) return;
        UpdateGridToggle();
        selectionChanged_();
    });
    grid_->Bind(wxEVT_LIST_ITEM_ACTIVATED, [this](wxListEvent &event) {
        const auto row = event.GetIndex();
        if (!picking_ && row >= 0 && static_cast<std::size_t>(row) < visibleIds_.size()) edit_(visibleIds_[row]);
    });
    grid_->Bind(wxEVT_CONTEXT_MENU, [this](wxContextMenuEvent &event) {
        if (event.GetPosition() != wxDefaultPosition) {
            int flags = 0;
            const auto row = grid_->HitTest(grid_->ScreenToClient(event.GetPosition()), flags);
            if (row < 0 || !(flags & wxLIST_HITTEST_ONITEM)) return;
            if (!(grid_->GetItemState(row, wxLIST_STATE_SELECTED) & wxLIST_STATE_SELECTED)) {
                grid_->SetItemState(-1, 0, wxLIST_STATE_SELECTED);
                grid_->SetItemState(row, wxLIST_STATE_SELECTED | wxLIST_STATE_FOCUSED,
                    wxLIST_STATE_SELECTED | wxLIST_STATE_FOCUSED);
            }
            grid_->SetFocus();
        }
        ShowContextMenu(event.GetPosition());
    });
    gridToggle_->Bind(wxEVT_CHECKBOX, [this](wxCommandEvent &) {
        const auto selected = SelectedIds();
        if (!picking_ && selected.size() == 1) tunnel_.SetEnabled(selected.front(), gridToggle_->GetValue());
        snapshot_ = tunnel_.Snapshot();
        RenderRows();
    });
    search_->Bind(wxEVT_TEXT, [this](wxCommandEvent &) {
        RenderRows();
        selectionChanged_();
    });
    list_->Bind(wxEVT_DATAVIEW_SELECTION_CHANGED, [this](wxDataViewEvent &) {
        if (!rendering_) selectionChanged_();
    });
    list_->Bind(wxEVT_DATAVIEW_ITEM_VALUE_CHANGED, &ProfileCollectionView::ToggleProfile, this);
    list_->Bind(wxEVT_DATAVIEW_ITEM_ACTIVATED, [this](wxDataViewEvent &event) {
        if (event.GetColumn() == ThemeProfileList::ToggleColumn || picking_) return;
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
void ProfileCollectionView::Render(const AppSnapshot &state, bool picking) {
    snapshot_ = state;
    picking_ = picking;
    RenderRows();
}
std::vector<std::string> ProfileCollectionView::SelectedIds() const {
    std::vector<std::string> ids;
    if (gridLayout_) {
        for (long row = grid_->GetNextItem(-1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED); row >= 0;
             row = grid_->GetNextItem(row, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED)) {
            if (static_cast<std::size_t>(row) < visibleIds_.size()) ids.push_back(visibleIds_[row]);
        }
        return ids;
    }
    wxDataViewItemArray selected;
    list_->GetSelections(selected);
    for (const auto &item : selected) {
        const auto row = list_->ItemToRow(item);
        if (row >= 0 && static_cast<std::size_t>(row) < visibleIds_.size()) ids.push_back(visibleIds_[row]);
    }
    return ids;
}
void ProfileCollectionView::RenderRows() {
    rendering_ = true;
    const auto selected = SelectedIds();
    list_->Freeze();
    grid_->Freeze();
    const auto query = search_->GetValue().Lower();
    std::vector<std::string> ids;
    for (const auto &profile : snapshot_.profiles) {
        if (query.empty() || Text(profile.name).Lower().Contains(query)) ids.push_back(profile.id);
    }
    const bool rebuild = ids != visibleIds_;
    if (rebuild) {
        list_->DeleteAllItems();
        grid_->DeleteAllItems();
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
        if (rebuild) list_->AppendProfile(Text(profile.name), status, toggle.isOn, toggle.canInteract && !picking_, transfer);
        else list_->UpdateProfile(row, Text(profile.name), status, toggle.isOn, toggle.canInteract && !picking_, transfer);
        if (rebuild) grid_->AppendProfile(Text(profile.name), status, transfer);
        else grid_->UpdateProfile(row, Text(profile.name), status, transfer);
        ++row;
    }
    if (rebuild) RestoreSelection(selected);
    list_->Thaw();
    grid_->Thaw();
    rendering_ = false;
    UpdateGridToggle();
}
void ProfileCollectionView::RestoreSelection(const std::vector<std::string> &ids) {
    const bool wasRendering = rendering_;
    rendering_ = true;
    list_->UnselectAll();
    grid_->SetItemState(-1, 0, wxLIST_STATE_SELECTED);
    for (std::size_t row = 0; row < visibleIds_.size(); ++row) {
        if (std::find(ids.begin(), ids.end(), visibleIds_[row]) == ids.end()) continue;
        list_->SelectRow(static_cast<unsigned>(row));
        grid_->SetItemState(static_cast<long>(row), wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED);
    }
    rendering_ = wasRendering;
}
void ProfileCollectionView::UpdateGridToggle() {
    const auto ids = SelectedIds();
    const auto state = ids.size() == 1 ? TunnelObservable::StateForProfile(snapshot_, ids.front()) : TunnelObservable::ToggleState{};
    gridToggle_->Enable(!picking_ && state.canInteract);
    gridToggle_->SetValue(state.isOn);
}
void ProfileCollectionView::ToggleProfile(wxDataViewEvent &event) {
    if (picking_ || rendering_ || event.GetColumn() != ThemeProfileList::ToggleColumn) return;
    const auto row = list_->ItemToRow(event.GetItem());
    if (row < 0 || static_cast<std::size_t>(row) >= visibleIds_.size()) return;
    tunnel_.SetEnabled(visibleIds_[row], list_->GetToggleValue(row, ThemeProfileList::ToggleColumn));
    // Restore observed state immediately; the next snapshot supplies completion
    // or failure instead of displaying an optimistic connection as successful.
    snapshot_ = tunnel_.Snapshot();
    RenderRows();
}
bool ProfileCollectionView::HasCollectionFocus() const {
    auto *focus = wxWindow::FindFocus();
    return focus && (focus == list_ || list_->IsDescendant(focus) || focus == grid_ || grid_->IsDescendant(focus));
}
void ProfileCollectionView::ShowContextMenu(const wxPoint &screenPosition) {
    const auto ids = SelectedIds();
    if (ids.empty()) return;
    wxWindow *collection = gridLayout_ ? static_cast<wxWindow *>(grid_) : list_;
    wxPoint position;
    if (screenPosition != wxDefaultPosition) position = collection->ScreenToClient(screenPosition);
    else if (gridLayout_) {
        wxRect rect;
        const auto selected = grid_->GetNextItem(-1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
        if (selected >= 0) grid_->GetItemRect(selected, rect);
        position = rect.GetBottomLeft();
    } else position = list_->GetItemRect(list_->GetCurrentItem()).GetBottomLeft();
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
}
