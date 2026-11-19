// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ThemeModal.h"
#include "../../strings/Strings.h"
#include <wx/display.h>

namespace Passepartout {
ThemeModal::ThemeModal(wxWindow *parent, const wxString &title,
    const std::function<wxWindow *(wxWindow *)> &makeContent, Mode mode, Sizing sizing)
    : wxDialog(parent, wxID_ANY, title, wxDefaultPosition, wxDefaultSize,
        wxDEFAULT_DIALOG_STYLE | (sizing == Sizing::FixedContent ? 0 : wxRESIZE_BORDER)) {
    Theme::Apply(this);
    auto *layout = new wxBoxSizer(wxVERTICAL);
    layout->Add(makeContent(this), 1, wxEXPAND);
    auto *buttons = new wxStdDialogButtonSizer;
    auto *close = new wxButton(this, wxID_CANCEL, Localized(mode == Mode::Editable ? StringKey::GlobalActionsCancel : StringKey::GlobalActionsClose));
    buttons->SetCancelButton(close);
    if (mode == Mode::Editable) {
        auto *ok = new wxButton(this, wxID_OK, Localized(StringKey::GlobalNounsOk));
        buttons->SetAffirmativeButton(ok);
        SetAffirmativeId(wxID_OK);
        ok->SetDefault();
        ok->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
            EndModal(wxID_OK);
        });
    }
    buttons->Realize();
    layout->Add(buttons, 0, (sizing == Sizing::FixedContent ? wxALIGN_CENTER_HORIZONTAL : wxALIGN_RIGHT) | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    SetEscapeId(wxID_CANCEL);
    close->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        EndModal(wxID_CANCEL);
    });
    auto size = GetBestSize();
    if (sizing == Sizing::Reading) size.IncTo(wxSize(GetCharWidth() * 80, GetCharHeight() * 24));
    size.DecTo(wxDisplay(this).GetClientArea().GetSize());
    SetSize(size);
    CentreOnParent();
}
}
