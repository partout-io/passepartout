// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../extensions/StateObserver.h"
#include "../../observables/ProfileObservable.h"
#include "../../business/strategy/WireGuardKeyGenerator.h"
#include <wx/wx.h>
#include <wx/simplebook.h>
#include <wx/activityindicator.h>

namespace Passepartout {
class ProfileModuleList;
class ProfileCoordinator final : public wxDialog {
public:
    ProfileCoordinator(wxWindow *parent, ProfileObservable &profiles,
        std::shared_ptr<ProfileEditor> editor, const WireGuardKeyGenerator &wireguard_keygen
    );
private:
    void SelectSection(std::size_t selection);
    void OpenModule(std::size_t index);
    void ShowSection(wxWindow *page, const wxString &title);
    void Dismiss();
    void RefreshState();
    ProfileObservable &profiles_;
    std::shared_ptr<ProfileEditor> editor_;
    const WireGuardKeyGenerator &wireguard_keygen_;
    wxSimplebook *pages_;
    ProfileModuleList *modules_;
    std::size_t selection_ = 0;
    wxButton *save_;
    wxButton *cancel_;
    wxActivityIndicator *progress_;
    StateObserver observer_;
};
}
