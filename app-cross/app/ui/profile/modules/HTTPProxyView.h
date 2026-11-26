// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../ModuleDetailView.h"
#include <partout/models/HTTPProxyModule.h>

namespace Passepartout {
class HTTPProxyView final : public ModuleDetailView {
public:
    HTTPProxyView(wxWindow *parent, const Partout::Models::HTTPProxyModule &module, OpenModuleContent open_content);
};
}
