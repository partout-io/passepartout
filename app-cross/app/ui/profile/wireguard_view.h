// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "module_detail_view.h"
#include <partout/models/WireGuardModule.h>
#include "../../business/wireguard_key_generator.h"

namespace Passepartout {
class WireGuardView final : public ModuleDetailView {
public:
    WireGuardView(wxWindow *parent, const Partout::Models::WireGuardModule &module, OpenModuleContent openContent, const WireGuardKeyGenerator &keys);
};
}
