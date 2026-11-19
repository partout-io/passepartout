// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include "../../observables/InteractiveLogin.h"

namespace Passepartout {
class InteractiveLoginView final : public ThemeDetailView {
public:
    InteractiveLoginView(wxWindow *parent, InteractiveLogin &login);
};
}
