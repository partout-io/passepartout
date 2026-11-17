// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/detail_view.h"
#include "../../observables/diagnostics_observable.h"
#include "../../observables/user_preferences_observable.h"
#include "navigation.h"

namespace Passepartout {
class DiagnosticsView final : public ThemeDetailView {
public:
    DiagnosticsView(wxWindow *parent, DiagnosticsObservable &diagnostics,
                    UserPreferencesObservable &preferences, SettingsNavigation navigate);
private:
    wxTimer timer_;
};
}
