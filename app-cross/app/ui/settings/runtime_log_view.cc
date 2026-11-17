// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "runtime_log_view.h"
#include "../../strings/strings.h"
#include "../../theme/theme.h"

namespace Passepartout {
RuntimeLogView::RuntimeLogView(wxWindow *parent, DiagnosticsObservable &diagnostics, bool tunnel)
    : wxPanel(parent), diagnostics_(diagnostics), tunnel_(tunnel), timer_(this) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    content_ = new wxTextCtrl(this, wxID_ANY, {}, wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY | wxTE_MULTILINE | wxTE_BESTWRAP | wxBORDER_NONE);
    Theme::Apply(this);
    content_->SetBackgroundColour(GetBackgroundColour());
    content_->SetName(Localized(tunnel ? StringKey::ViewsDiagnosticsRowsTunnel : StringKey::ViewsDiagnosticsRowsApp));
    content_->SetFont(wxFontInfo(content_->GetFont().GetPointSize()).Family(wxFONTFAMILY_TELETYPE));
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
