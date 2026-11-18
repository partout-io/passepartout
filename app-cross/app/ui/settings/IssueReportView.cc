// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "IssueReportView.h"
#include "../Presentation.h"

namespace Passepartout {
IssueReportView::IssueReportView(wxWindow *parent, DiagnosticsObservable &diagnostics) : ThemeDetailView(parent) {
    auto *comment = TextField(Localized(StringKey::GlobalNounsComment), {}, wxTE_MULTILINE);
    comment->SetMinSize(FromDIP(wxSize(-1, 200)));
    comment->SetMaxLength(16000);
    Action(Localized(StringKey::ViewsDiagnosticsReportIssueTitle), [this, comment, &diagnostics] {
        try {
            if (!diagnostics.Report(comment->GetValue().ToStdString(wxConvUTF8))) {
                PresentError(this, StringKey::ViewsDiagnosticsAlertsReportIssueEmail);
            }
        } catch (...) {
            PresentError(this);
        }
    });
    Finish();
}
}
