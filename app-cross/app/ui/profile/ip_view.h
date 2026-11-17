// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "module_detail_view.h"
#include <partout/models/IPModule.h>

namespace Passepartout {
class IPView final : public ModuleDetailView {
public:
    IPView(wxWindow *parent, const Partout::Models::IPModule &module, OpenModuleContent openContent);
};
}
