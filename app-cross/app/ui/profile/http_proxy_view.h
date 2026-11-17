// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "module_detail_view.h"
#include <partout/models/HTTPProxyModule.h>

namespace Passepartout {
class HTTPProxyView final : public ModuleDetailView {
public:
    HTTPProxyView(wxWindow *parent, const Partout::Models::HTTPProxyModule &module, OpenModuleContent openContent);
};
}
