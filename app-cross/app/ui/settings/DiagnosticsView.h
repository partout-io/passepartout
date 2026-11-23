// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include "../../observables/DiagnosticsObservable.h"
#include "../../observables/UserPreferencesObservable.h"
#include "SettingsPresentation.h"

namespace Passepartout {
class DiagnosticsView final : public ThemeDetailView {
public:
    DiagnosticsView(wxWindow *parent, DiagnosticsObservable &diagnostics,
                    UserPreferencesObservable &preferences, SettingsPresentation present, std::function<void()> report_issue);
private:
    wxTimer timer_;
};
}
