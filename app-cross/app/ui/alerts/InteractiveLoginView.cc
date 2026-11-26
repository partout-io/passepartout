// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "InteractiveLoginView.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
InteractiveLoginView::InteractiveLoginView(wxWindow *parent, InteractiveLogin &login)
    : ThemeDetailView(parent, Presentation::Form) {
    wxTextCtrl *username = nullptr;
    if (!login.needs_otp) {
        username = TextField(Localized(StringKey::GlobalNounsUsername), wxString::FromUTF8(login.credentials.username));
        username->SetMinSize(wxSize(GetCharWidth() * 32, -1));
        username->Bind(wxEVT_TEXT, [&login, username](wxCommandEvent &) {
            login.credentials.username = username->GetValue().ToStdString(wxConvUTF8);
        });
    }
    auto *password = TextField(login.needs_otp ? wxString(Strings::Unlocalized::OTP) : Localized(StringKey::GlobalNounsPassword),
        wxString::FromUTF8(login.credentials.password), wxTE_PASSWORD);
    password->SetMinSize(wxSize(GetCharWidth() * 32, -1));
    password->Bind(wxEVT_TEXT, [&login, password](wxCommandEvent &) {
        login.credentials.password = password->GetValue().ToStdString(wxConvUTF8);
    });
    if (username) username->SetFocus();
    else password->SetFocus();
    Finish();
    SetMinSize(GetSizer()->GetMinSize());
}
}
