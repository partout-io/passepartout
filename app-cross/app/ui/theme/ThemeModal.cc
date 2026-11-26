// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ThemeModal.h"
#include "../../strings/Strings.h"
#include <wx/display.h>

namespace Passepartout {
ThemeModal::ThemeModal(wxWindow *parent, const wxString &title,
    const std::function<wxWindow *(wxWindow *)> &make_content, Mode mode, Sizing sizing, std::function<bool()> can_accept
)
    : wxDialog(parent, wxID_ANY, title, wxDefaultPosition, wxDefaultSize,
        wxDEFAULT_DIALOG_STYLE | (sizing == Sizing::FixedContent ? 0 : wxRESIZE_BORDER)) {
    Theme::Apply(this);
    auto *layout = new wxBoxSizer(wxVERTICAL);
    auto *content = make_content(this);
    layout->Add(content, 1, wxEXPAND);
    auto *buttons = new wxStdDialogButtonSizer;
    auto *close = new wxButton(this, wxID_CANCEL, Localized(mode == Mode::Editable ? StringKey::GlobalActionsCancel : StringKey::GlobalActionsClose));
    buttons->SetCancelButton(close);
    if (mode == Mode::Editable) {
        auto *ok = new wxButton(this, wxID_OK, Localized(StringKey::GlobalNounsOk));
        buttons->SetAffirmativeButton(ok);
        SetAffirmativeId(wxID_OK);
        ok->SetDefault();
        if (can_accept) {
            ok->Enable(can_accept());
            Bind(wxEVT_UPDATE_UI, [can_accept](wxUpdateUIEvent &event) {
                event.Enable(can_accept());
            }, wxID_OK);
            Bind(wxEVT_BUTTON, [this, can_accept](wxCommandEvent &) {
                // Recheck at submission: button state may lag behind input.
                if (can_accept()) EndModal(wxID_OK);
            }, wxID_OK);
        }
    }
    buttons->Realize();
    layout->Add(buttons, 0, (sizing == Sizing::FixedContent ? wxALIGN_CENTER_HORIZONTAL : wxALIGN_RIGHT) | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    SetEscapeId(wxID_CANCEL);
    auto size = GetBestSize();
    const auto available = wxDisplay(this).GetClientArea().GetSize();
    if (sizing == Sizing::TextInput) {
        // The content's 40-character by 8-line editor minimum includes its
        // caption and padding. Add only the editor delta for the 60-by-12 default.
        auto minimum = size;
        minimum.DecTo(available);
        SetMinSize(minimum);
        size += wxSize(content->GetCharWidth() * 20, content->GetCharHeight() * 4);
    }
    if (sizing == Sizing::Reading) size.IncTo(wxSize(GetCharWidth() * 80, GetCharHeight() * 24));
    size.DecTo(available);
    if (sizing == Sizing::FixedContent) {
        layout->Fit(this);
    } else {
        SetSize(size);
    }
    CentreOnParent();
}
}
