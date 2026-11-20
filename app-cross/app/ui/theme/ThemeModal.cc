// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ThemeModal.h"
#include "../../strings/Strings.h"
#include <wx/display.h>

namespace Passepartout {
ThemeModal::ThemeModal(wxWindow *parent, const wxString &title,
    const std::function<wxWindow *(wxWindow *)> &makeContent, Mode mode, Sizing sizing, std::function<bool()> canAccept)
    : wxDialog(parent, wxID_ANY, title, wxDefaultPosition, wxDefaultSize,
        wxDEFAULT_DIALOG_STYLE | (sizing == Sizing::FixedContent ? 0 : wxRESIZE_BORDER)) {
    Theme::Apply(this);
    auto *layout = new wxBoxSizer(wxVERTICAL);
    auto *content = makeContent(this);
    layout->Add(content, 1, wxEXPAND);
    auto *buttons = new wxStdDialogButtonSizer;
    auto *close = new wxButton(this, wxID_CANCEL, Localized(mode == Mode::Editable ? StringKey::GlobalActionsCancel : StringKey::GlobalActionsClose));
    buttons->SetCancelButton(close);
    if (mode == Mode::Editable) {
        auto *ok = new wxButton(this, wxID_OK, Localized(StringKey::GlobalNounsOk));
        buttons->SetAffirmativeButton(ok);
        SetAffirmativeId(wxID_OK);
        ok->SetDefault();
        ok->Enable(!canAccept || canAccept());
        ok->Bind(wxEVT_UPDATE_UI, [canAccept](wxUpdateUIEvent &event) {
            event.Enable(!canAccept || canAccept());
        });
        ok->Bind(wxEVT_BUTTON, [this, canAccept](wxCommandEvent &) {
            if (canAccept && !canAccept()) return;
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
