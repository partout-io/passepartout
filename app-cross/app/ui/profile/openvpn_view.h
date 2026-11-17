// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "module_detail_view.h"
#include <partout/models/OpenVPNModule.h>

namespace Passepartout {
class OpenVPNView final : public ModuleDetailView {
public:
    OpenVPNView(wxWindow *parent, const Partout::Models::OpenVPNModule &module, OpenModuleContent openContent, std::function<void()> openCredentials);
};
}
