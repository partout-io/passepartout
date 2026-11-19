// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "RuntimeLogView.h"
#include "../../strings/Strings.h"
#include "../theme/Theme.h"

namespace Passepartout {
RuntimeLogView::RuntimeLogView(wxWindow *parent, DiagnosticsObservable &diagnostics, bool tunnel)
    : wxPanel(parent), diagnostics_(diagnostics), tunnel_(tunnel), timer_(this) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    content_ = new wxTextCtrl(this, wxID_ANY, {}, wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY | wxTE_MULTILINE | wxTE_BESTWRAP);
    content_->SetName(Localized(tunnel ? StringKey::ViewsDiagnosticsRowsTunnel : StringKey::ViewsDiagnosticsRowsApp));
    Theme::Monospace(content_);
    layout->Add(content_, 1, wxEXPAND | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    Bind(wxEVT_TIMER, [this](wxTimerEvent &) {
        UpdateContent();
    });
    UpdateContent();
    timer_.Start(1000);
}
void RuntimeLogView::UpdateContent() {
    const auto log = tunnel_ ? diagnostics_.TunnelLog() : std::optional(diagnostics_.ApplicationLog());
    const auto text = log ? wxString::FromUTF8(*log) : Localized(StringKey::ViewsDiagnosticsRuntimeUnavailable);
    if (content_->GetValue() == text) return;
    long from = 0, to = 0;
    content_->GetSelection(&from, &to);
    content_->ChangeValue(text);
    content_->SetSelection(from, to);
}
}
