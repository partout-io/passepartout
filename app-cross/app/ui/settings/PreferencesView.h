// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/ThemeDetailView.h"
#include "../../observables/UserPreferencesObservable.h"

namespace Passepartout {
class PreferencesView final : public ThemeDetailView {
public:
    PreferencesView(wxWindow *parent, UserPreferencesObservable &preferences);
};
}
