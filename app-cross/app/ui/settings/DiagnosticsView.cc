// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "DiagnosticsView.h"
#include "RuntimeLogView.h"
#include "IssueReportView.h"
#include "../extensions/Presentation.h"

namespace Passepartout {
DiagnosticsView::DiagnosticsView(wxWindow *parent, DiagnosticsObservable &diagnostics,
    UserPreferencesObservable &preferences, SettingsPresentation present) : ThemeDetailView(parent, Presentation::Plain), timer_(this) {
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
    const auto refreshLogging = [this, privacy, extensive, &preferences] {
        const bool canChange = preferences.CanChangePrivateData();
        privacy->Enable(canChange);
        SetToggleSupport(privacy, Localized(canChange
            ? StringKey::ViewsDiagnosticsRowsIncludePrivateDataSubtitle
            : StringKey::ViewsDiagnosticsRowsIncludePrivateDataDisableProfiles));
        SetToggleSupport(extensive, Localized(canChange
            ? StringKey::ViewsDiagnosticsRowsExtensiveLoggingSubtitle
            : StringKey::ViewsDiagnosticsRowsIncludePrivateDataDisableProfiles));
    };
    refreshLogging();
    privacy->Bind(wxEVT_CHECKBOX, [this, privacy, &preferences](wxCommandEvent &) {
        try {
            preferences.SetLogsPrivateData(privacy->GetValue());
        } catch (...) {
            privacy->SetValue(preferences.Snapshot().logsPrivateData);
            PresentError(this);
        }
    });
    Bind(wxEVT_TIMER, [refreshLogging](wxTimerEvent &) {
        refreshLogging();
    });
    timer_.Start(200);
    EndSection();
    ButtonRow(Localized(StringKey::ViewsDiagnosticsReportIssueTitle), [&diagnostics, present] {
        present(Localized(StringKey::ViewsDiagnosticsReportIssueTitle), [&diagnostics](wxWindow *parent) {
            return new IssueReportView(parent, diagnostics);
        });
    });
    Finish();
}
}
