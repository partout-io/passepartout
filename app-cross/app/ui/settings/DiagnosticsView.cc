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
        ContentLink(title, [title, tunnel, &diagnostics, present] {
            present(title, [&diagnostics, tunnel](wxWindow *parent) {
                return new RuntimeLogView(parent, diagnostics, tunnel);
            });
        });
    }
    auto *privacy = Toggle(Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateData),
        Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateDataSubtitle), preferences.Snapshot().logsPrivateData);
    Message(Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateDataDisableProfiles), TextStyle::Secondary);
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
    Section(Localized(StringKey::ViewsDiagnosticsReportIssueTitle));
    ContentLink(Localized(StringKey::ViewsDiagnosticsReportIssueTitle), [&diagnostics, present] {
        present(Localized(StringKey::ViewsDiagnosticsReportIssueTitle), [&diagnostics](wxWindow *parent) {
            return new IssueReportView(parent, diagnostics);
        });
    });
    Finish();
}
}
