// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/ThemeDetailView.h"
#include "../../observables/DiagnosticsObservable.h"
#include "../../observables/UserPreferencesObservable.h"
#include "SettingsNavigation.h"

namespace Passepartout {
class DiagnosticsView final : public ThemeDetailView {
public:
    DiagnosticsView(wxWindow *parent, DiagnosticsObservable &diagnostics,
                    UserPreferencesObservable &preferences, SettingsNavigation navigate);
private:
    wxTimer timer_;
};
}
