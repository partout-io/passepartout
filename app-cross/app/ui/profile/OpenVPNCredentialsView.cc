// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "OpenVPNCredentialsView.h"
#include "../../strings/Strings.h"

namespace Passepartout {
OpenVPNCredentialsView::OpenVPNCredentialsView(wxWindow *parent,
    const Partout::Models::OpenVpnCredentials &credentials,
    std::function<void(std::string, std::string)> updateCredentials)
    : ThemeDetailView(parent, Presentation::Form) {
    auto *username = TextField(Localized(StringKey::GlobalNounsUsername), wxString::FromUTF8(credentials.username));
    auto *password = TextField(Localized(StringKey::GlobalNounsPassword), wxString::FromUTF8(credentials.password), wxTE_PASSWORD);
    username->SetMinSize(wxSize(GetCharWidth() * 32, -1));
    password->SetMinSize(wxSize(GetCharWidth() * 32, -1));
    const auto update = [username, password, updateCredentials](wxCommandEvent &) {
        updateCredentials(username->GetValue().ToStdString(wxConvUTF8),
            password->GetValue().ToStdString(wxConvUTF8));
    };
    username->Bind(wxEVT_TEXT, update);
    password->Bind(wxEVT_TEXT, update);
    Finish();
    SetMinSize(GetSizer()->GetMinSize());
}
}
