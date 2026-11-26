// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "DiagnosticsView.h"
#include "RuntimeLogView.h"
#include "../platform/Presentation.h"

namespace Passepartout {
DiagnosticsView::DiagnosticsView(wxWindow *parent, DiagnosticsObservable &diagnostics,
    UserPreferencesObservable &preferences, ProfileObservable &profiles, TunnelObservable &tunnel,
    SettingsPresentation present, std::function<void()> report_issue
) : ThemeDetailView(parent, Presentation::Plain), preferences_(preferences), observer_([this] { RefreshLogging(); }) {
    Section(Localized(StringKey::ViewsDiagnosticsSectionsLive));
    for (const bool tunnel_log : {false, true}) {
        const auto title = Localized(tunnel_log ? StringKey::ViewsDiagnosticsRowsTunnel : StringKey::ViewsDiagnosticsRowsApp);
        const bool available = !tunnel_log || diagnostics.TunnelLog().has_value();
        auto *button = ButtonRow(title, [title, tunnel_log, &diagnostics, present] {
            present(title, [&diagnostics, tunnel_log](wxWindow *parent) {
                return new RuntimeLogView(parent, diagnostics, tunnel_log);
            });
        }, available ? wxString() : Localized(StringKey::ViewsDiagnosticsRuntimeUnavailable));
        button->Enable(available);
    }
    Section({});
    extensive_ = Toggle(Localized(StringKey::ViewsDiagnosticsRowsExtensiveLogging),
        Localized(StringKey::ViewsDiagnosticsRowsExtensiveLoggingSubtitle), false
    );
    extensive_->Enable(false);
    privacy_ = Toggle(Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateData),
        Localized(StringKey::ViewsDiagnosticsRowsIncludePrivateDataSubtitle), false
    );
    privacy_->Bind(wxEVT_CHECKBOX, [this](wxCommandEvent &) {
        try {
            preferences_.SetLogsPrivateData(privacy_->GetValue());
        } catch (...) {
            RefreshLogging();
            PresentError(this);
        }
    });
    observer_.Observe(preferences.changes);
    observer_.Observe(profiles.changes);
    observer_.Observe(tunnel.changes);
    RefreshLogging();
    EndSection();
    ButtonRow(Localized(StringKey::ViewsDiagnosticsReportIssueTitle), std::move(report_issue));
    Finish();
}

void DiagnosticsView::RefreshLogging() {
    privacy_->SetValue(preferences_.Snapshot().logsPrivateData);
    const bool can_change = preferences_.CanChangePrivateData();
    privacy_->Enable(can_change);
    SetToggleSupport(privacy_, Localized(can_change
        ? StringKey::ViewsDiagnosticsRowsIncludePrivateDataSubtitle
        : StringKey::ViewsDiagnosticsRowsIncludePrivateDataDisableProfiles)
    );
    SetToggleSupport(extensive_, Localized(can_change
        ? StringKey::ViewsDiagnosticsRowsExtensiveLoggingSubtitle
        : StringKey::ViewsDiagnosticsRowsIncludePrivateDataDisableProfiles)
    );
}
}
