// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../observables/profile_observable.h"
#include "../observables/tunnel_observable.h"
#include "../theme/theme.h"
#include "../theme/profile_list.h"
#include "../theme/profile_grid.h"
#include <wx/srchctrl.h>
#include <wx/simplebook.h>
#include <functional>

namespace Passepartout {
// Owns filtering and native selection. Actions leave the collection with stable
// identities, never row numbers or references into a rendered snapshot.
class ProfileCollectionView final : public wxPanel {
public:
    ProfileCollectionView(wxWindow *parent, TunnelObservable &tunnel,
        std::function<void()> selectionChanged,
        std::function<void(std::vector<std::string>)> remove,
        std::function<void(std::string)> edit);
    void Render(const AppSnapshot &state, bool picking);
    std::vector<std::string> SelectedIds() const;
    bool HasCollectionFocus() const;
    void ShowContextMenu(const wxPoint &screenPosition);
private:
    void RenderRows();
    void ToggleProfile(wxDataViewEvent &event);
    void RestoreSelection(const std::vector<std::string> &ids);
    void UpdateGridToggle();
    TunnelObservable &tunnel_;
    std::function<void()> selectionChanged_;
    std::function<void(std::vector<std::string>)> remove_;
    std::function<void(std::string)> edit_;
    wxSearchCtrl *search_;
    ThemeProfileList *list_;
    ThemeProfileGrid *grid_;
    wxSimplebook *layouts_;
    wxCheckBox *gridToggle_;
    bool gridLayout_ = false;
    AppSnapshot snapshot_;
    std::vector<std::string> visibleIds_;
    bool picking_ = false;
    bool rendering_ = false;
};
}
