// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ThemeModal.h"
#include "../strings/Strings.h"
#include <wx/display.h>

namespace Passepartout {
ThemeModal::ThemeModal(wxWindow *parent, const wxString &title,
    const std::function<wxWindow *(wxWindow *)> &makeContent)
    : wxDialog(parent, wxID_ANY, title, wxDefaultPosition, wxDefaultSize,
        wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    layout->Add(makeContent(this), 1, wxEXPAND);
    auto *buttons = new wxStdDialogButtonSizer;
    auto *close = new wxButton(this, wxID_CANCEL, Localized(StringKey::GlobalActionsClose));
    buttons->SetCancelButton(close);
    buttons->Realize();
    layout->Add(buttons, 0, wxALIGN_RIGHT | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    SetEscapeId(wxID_CANCEL);
    close->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        EndModal(wxID_CANCEL);
    });
    auto size = wxSize(GetCharWidth() * 80, GetCharHeight() * 24);
    size.IncTo(GetBestSize());
    size.DecTo(wxDisplay(this).GetClientArea().GetSize());
    SetSize(size);
    CentreOnParent();
}
}
