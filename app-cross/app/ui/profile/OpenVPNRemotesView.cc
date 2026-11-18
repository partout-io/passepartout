// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "OpenVPNRemotesView.h"
#include "../../strings/Strings.h"

namespace Passepartout {
OpenVPNRemotesView::OpenVPNRemotesView(wxWindow *parent, const std::vector<std::string> &endpoints)
    : ThemeDetailView(parent, Presentation::Form) {
    std::vector<wxString> values;
    for (const auto &endpoint : endpoints) values.push_back(wxString::FromUTF8(endpoint));
    Items({}, values);
    Finish();
}
}
