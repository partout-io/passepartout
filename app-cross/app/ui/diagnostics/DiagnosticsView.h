// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../extensions/StateObserver.h"
#include "../../observables/ProfileObservable.h"
#include "../../observables/TunnelObservable.h"
#include "../theme/ThemeDetailView.h"
#include "../../observables/DiagnosticsObservable.h"
#include "../../observables/UserPreferencesObservable.h"
#include "../settings/SettingsPresentation.h"

namespace Passepartout {
class DiagnosticsView final : public ThemeDetailView {
public:
    DiagnosticsView(wxWindow *parent, DiagnosticsObservable &diagnostics,
                    UserPreferencesObservable &preferences, ProfileObservable &profiles, TunnelObservable &tunnel,
                    SettingsPresentation present, std::function<void()> report_issue
    );
private:
    void RefreshLogging();
    UserPreferencesObservable &preferences_;
    wxCheckBox *privacy_;
    wxCheckBox *extensive_;
    StateObserver observer_;
};
}
