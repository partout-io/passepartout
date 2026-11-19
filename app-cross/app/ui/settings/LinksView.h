// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include "AppConstants.h"

namespace Passepartout {
class LinksView final : public ThemeDetailView {
public:
    LinksView(wxWindow *parent, const Models::AppConstants &constants);
};
}
