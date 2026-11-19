// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include <partout/models/OpenVpnCredentials.h>

namespace Passepartout {
class OpenVPNCredentialsView final : public ThemeDetailView {
public:
    OpenVPNCredentialsView(wxWindow *parent, const Partout::Models::OpenVpnCredentials &credentials,
        std::function<void(std::string, std::string)> updateCredentials);
};
}
