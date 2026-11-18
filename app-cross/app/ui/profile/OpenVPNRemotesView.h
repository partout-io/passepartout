// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/ThemeDetailView.h"
#include <string>
#include <vector>

namespace Passepartout {
class OpenVPNRemotesView final : public ThemeDetailView {
public:
    OpenVPNRemotesView(wxWindow *parent, const std::vector<std::string> &endpoints);
};
}
