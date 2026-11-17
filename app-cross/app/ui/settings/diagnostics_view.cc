// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "diagnostics_view.h"
#include "runtime_log_view.h"
#include "issue_report_view.h"
#include "../presentation.h"

namespace Passepartout {
DiagnosticsView::DiagnosticsView(wxWindow *parent, DiagnosticsObservable &diagnostics,
    UserPreferencesObservable &preferences, SettingsNavigation navigate) : ThemeDetailView(parent), timer_(this) {
    Section(Localized(StringKey::ViewsDiagnosticsSectionsLive));
    for (const bool tunnel : {false, true}) {
        const auto title = Localized(tunnel ? StringKey::ViewsDiagnosticsRowsTunnel : StringKey::ViewsDiagnosticsRowsApp);
        Action(title, [title, tunnel, &diagnostics, navigate] {
            navigate(title, [&diagnostics, tunnel](wxWindow *parent) {
                return new RuntimeLogView(parent, diagnostics, tunnel);
            });
        });
    }
    auto *privacy = Toggle(Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateData),
        Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateDataSubtitle), preferences.Snapshot().logsPrivateData);
    Message(Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateDataDisableProfiles));
    privacy->Enable(preferences.CanChangePrivateData());
    privacy->Bind(wxEVT_CHECKBOX, [this, privacy, &preferences](wxCommandEvent &) {
        try {
            preferences.SetLogsPrivateData(privacy->GetValue());
        } catch (...) {
            privacy->SetValue(preferences.Snapshot().logsPrivateData);
            PresentError(this);
        }
    });
    Bind(wxEVT_TIMER, [privacy, &preferences](wxTimerEvent &) {
        privacy->Enable(preferences.CanChangePrivateData());
    });
    timer_.Start(200);
    Action(Localized(StringKey::ViewsDiagnosticsReportIssueTitle), [&diagnostics, navigate] {
        navigate(Localized(StringKey::ViewsDiagnosticsReportIssueTitle), [&diagnostics](wxWindow *parent) {
            return new IssueReportView(parent, diagnostics);
        });
    });
    Finish();
}
}
