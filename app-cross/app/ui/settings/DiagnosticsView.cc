// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "DiagnosticsView.h"
#include "RuntimeLogView.h"
#include "../platform/Presentation.h"

namespace Passepartout {
DiagnosticsView::DiagnosticsView(wxWindow *parent, DiagnosticsObservable &diagnostics,
    UserPreferencesObservable &preferences, SettingsPresentation present, std::function<void()> report_issue) : ThemeDetailView(parent, Presentation::Plain), timer_(this) {
    Section(Localized(StringKey::ViewsDiagnosticsSectionsLive));
    for (const bool tunnel : {false, true}) {
        const auto title = Localized(tunnel ? StringKey::ViewsDiagnosticsRowsTunnel : StringKey::ViewsDiagnosticsRowsApp);
        const bool available = !tunnel || diagnostics.TunnelLog().has_value();
        auto *button = ButtonRow(title, [title, tunnel, &diagnostics, present] {
            present(title, [&diagnostics, tunnel](wxWindow *parent) {
                return new RuntimeLogView(parent, diagnostics, tunnel);
            });
        }, available ? wxString() : Localized(StringKey::ViewsDiagnosticsRuntimeUnavailable));
        button->Enable(available);
    }
    Section({});
    auto *extensive = Toggle(Localized(StringKey::ViewsDiagnosticsRowsExtensiveLogging),
        Localized(StringKey::ViewsDiagnosticsRowsExtensiveLoggingSubtitle), false);
    extensive->Enable(false);
    auto *privacy = Toggle(Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateData),
        Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateDataSubtitle), preferences.Snapshot().logsPrivateData);
    const auto refresh_logging = [this, privacy, extensive, &preferences] {
        const bool can_change = preferences.CanChangePrivateData();
        privacy->Enable(can_change);
        SetToggleSupport(privacy, Localized(can_change
            ? StringKey::ViewsDiagnosticsRowsIncludePrivateDataSubtitle
            : StringKey::ViewsDiagnosticsRowsIncludePrivateDataDisableProfiles));
        SetToggleSupport(extensive, Localized(can_change
            ? StringKey::ViewsDiagnosticsRowsExtensiveLoggingSubtitle
            : StringKey::ViewsDiagnosticsRowsIncludePrivateDataDisableProfiles));
    };
    refresh_logging();
    privacy->Bind(wxEVT_CHECKBOX, [this, privacy, &preferences](wxCommandEvent &) {
        try {
            preferences.SetLogsPrivateData(privacy->GetValue());
        } catch (...) {
            privacy->SetValue(preferences.Snapshot().logsPrivateData);
            PresentError(this);
        }
    });
    Bind(wxEVT_TIMER, [refresh_logging](wxTimerEvent &) {
        refresh_logging();
    });
    timer_.Start(200);
    EndSection();
    ButtonRow(Localized(StringKey::ViewsDiagnosticsReportIssueTitle), std::move(report_issue));
    Finish();
}
}
