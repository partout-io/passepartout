// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/panel.h>
#include <string>
#include <vector>

namespace Passepartout {
class OpenVPNRemotesView final : public wxPanel {
public:
    OpenVPNRemotesView(wxWindow *parent, const std::vector<std::string> &endpoints);
};
}
