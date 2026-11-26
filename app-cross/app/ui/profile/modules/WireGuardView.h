// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../ModuleDetailView.h"
#include <partout/models/WireGuardModule.h>
#include "../../../business/strategy/WireGuardKeyGenerator.h"

namespace Passepartout {
class WireGuardView final : public ModuleDetailView {
public:
    WireGuardView(wxWindow *parent, const Partout::Models::WireGuardModule &module, OpenModuleContent open_content, const WireGuardKeyGenerator &keys,
        std::function<void(wxString, std::vector<std::string>)> open_list);
};
}
