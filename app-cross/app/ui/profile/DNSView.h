// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ModuleDetailView.h"
#include <partout/models/DNSModule.h>

namespace Passepartout {
class DNSView final : public ModuleDetailView {
public:
    DNSView(wxWindow *parent, const Partout::Models::DNSModule &module, OpenModuleContent open_content);
};
}
