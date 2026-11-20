// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "RuntimeLogView.h"
#include "../../strings/Strings.h"

namespace Passepartout {
RuntimeLogView::RuntimeLogView(wxWindow *parent, DiagnosticsObservable &diagnostics, bool tunnel)
    : ThemeLongContent(parent, Localized(tunnel ? StringKey::ViewsDiagnosticsRowsTunnel : StringKey::ViewsDiagnosticsRowsApp), {}),
      diagnostics_(diagnostics), tunnel_(tunnel), timer_(this) {
    Bind(wxEVT_TIMER, [this](wxTimerEvent &) {
        UpdateContent();
    });
    UpdateContent();
    timer_.Start(1000);
}
void RuntimeLogView::UpdateContent() {
    const auto log = tunnel_ ? diagnostics_.TunnelLog() : std::optional(diagnostics_.ApplicationLog());
    const auto text = log ? wxString::FromUTF8(*log) : Localized(StringKey::ViewsDiagnosticsRuntimeUnavailable);
    SetContent(text);
}
}
