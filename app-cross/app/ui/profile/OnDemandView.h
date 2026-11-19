// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include <partout/models/OnDemandModule.h>

namespace Passepartout {
class OnDemandView final : public ThemeDetailView {
public:
    OnDemandView(wxWindow *parent, const Partout::Models::OnDemandModule &module);
};
}
