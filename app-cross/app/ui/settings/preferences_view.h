// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/detail_view.h"
#include "../../observables/user_preferences_observable.h"

namespace Passepartout {
class PreferencesView final : public ThemeDetailView {
public:
    PreferencesView(wxWindow *parent, UserPreferencesObservable &preferences);
};
}
