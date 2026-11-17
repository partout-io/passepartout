// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "module_detail_view.h"
#include <partout/models/DNSModule.h>

namespace Passepartout {
class DNSView final : public ModuleDetailView {
public:
    DNSView(wxWindow *parent, const Partout::Models::DNSModule &module, OpenModuleContent openContent);
};
}
