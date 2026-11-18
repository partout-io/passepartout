// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "OpenVPNCredentialsView.h"
#include "../../strings/Strings.h"

namespace Passepartout {
OpenVPNCredentialsView::OpenVPNCredentialsView(wxWindow *parent, std::shared_ptr<ProfileEditor> editor, std::size_t moduleIndex)
    : ThemeDetailView(parent, Presentation::Form) {
    const auto draft = editor->Snapshot().draft;
    const auto &module = std::get<Partout::Models::TaggedModuleOpenVpn>(draft.modules.at(moduleIndex));
    Partout::Models::OpenVpnCredentials credentials{};
    credentials.otpMethod.value = Partout::Models::OpenVpnCredentialsOTPMethod::none;
    if (module.value.credentials) credentials = *module.value.credentials;
    auto *username = TextField(Localized(StringKey::GlobalNounsUsername), wxString::FromUTF8(credentials.username));
    auto *password = TextField(Localized(StringKey::GlobalNounsPassword), wxString::FromUTF8(credentials.password), wxTE_PASSWORD);
    auto update = [editor, moduleIndex, username, password](wxCommandEvent &) {
        auto module = std::get<Partout::Models::TaggedModuleOpenVpn>(editor->Snapshot().draft.modules.at(moduleIndex));
        Partout::Models::OpenVpnCredentials credentials{};
        credentials.otpMethod.value = Partout::Models::OpenVpnCredentialsOTPMethod::none;
        if (module.value.credentials) credentials = *module.value.credentials;
        credentials.username = username->GetValue().ToStdString(wxConvUTF8);
        credentials.password = password->GetValue().ToStdString(wxConvUTF8);
        module.value.credentials = std::move(credentials);
        editor->UpdateModule(module);
    };
    username->Bind(wxEVT_TEXT, update);
    password->Bind(wxEVT_TEXT, update);
    Finish();
}
}
