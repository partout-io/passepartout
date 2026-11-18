// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../observables/ProfileObservable.h"
#include "../../business/WireGuardKeyGenerator.h"
#include <wx/wx.h>
#include <wx/simplebook.h>
#include <wx/activityindicator.h>

namespace Passepartout {
class ProfileEditorView final : public wxDialog {
public:
    ProfileEditorView(wxWindow *parent, ProfileObservable &profiles,
        std::shared_ptr<ProfileEditor> editor, const WireGuardKeyGenerator &keys);
private:
    void Overview();
    void OpenModule(std::size_t index);
    void Push(wxWindow *page, const wxString &title);
    void Back();
    void Refresh();
    ProfileObservable &profiles_;
    std::shared_ptr<ProfileEditor> editor_;
    const WireGuardKeyGenerator &keys_;
    wxSimplebook *pages_;
    wxButton *save_;
    wxButton *back_;
    wxButton *cancel_;
    wxActivityIndicator *progress_;
    wxTimer timer_;
    std::vector<wxString> titles_;
};
}
