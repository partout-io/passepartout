// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../observables/ProfileObservable.h"
#include "../../observables/TunnelObservable.h"
#include "../theme/Theme.h"
#include "../theme/ThemeList.h"
#include <wx/srchctrl.h>
#include <functional>

namespace Passepartout {
// Owns filtering and native selection. Actions leave the collection with stable
// identities, never row numbers or references into a rendered snapshot.
class ProfileListView final : public wxPanel {
public:
    ProfileListView(wxWindow *parent, TunnelObservable &tunnel,
        std::function<void()> selection_changed,
        std::function<void(std::vector<std::string>)> remove,
        std::function<void(std::string)> edit);
    static constexpr unsigned TransferColumn = 2;
    static constexpr unsigned ToggleColumn = 3;
    void Render(const AppSnapshot &state, bool picking);
    std::vector<std::string> SelectedIds() const;
    bool HasCollectionFocus() const;
    void ShowContextMenu(const wxPoint &screen_position);
private:
    void AppendProfile(const wxString &name, const wxString &status, bool is_on, bool enabled, const wxString &transfer);
    void UpdateProfile(unsigned row, const wxString &name, const wxString &status, bool is_on, bool enabled, const wxString &transfer);
    void RenderRows();
    void ToggleProfile(wxDataViewEvent &event);
    void RestoreSelection(const std::vector<std::string> &ids);
    TunnelObservable &tunnel_;
    std::function<void()> selection_changed_;
    std::function<void(std::vector<std::string>)> remove_;
    std::function<void(std::string)> edit_;
    wxSearchCtrl *search_;
    ThemeList *list_;
    AppSnapshot snapshot_;
    std::vector<std::string> visible_ids_;
    bool picking_ = false;
    bool rendering_ = false;
};
}
