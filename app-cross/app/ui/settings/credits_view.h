// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/detail_view.h"
#include "../../observables/credits_observable.h"
#include "navigation.h"

namespace Passepartout {
class CreditsView final : public ThemeDetailView {
public:
    CreditsView(wxWindow *parent, CreditsObservable &credits, SettingsNavigation navigate);
};
}
