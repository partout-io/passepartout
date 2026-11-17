// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "license_view.h"
#include "../../strings/strings.h"
#include "../../theme/theme.h"

namespace Passepartout {
LicenseView::LicenseView(wxWindow *parent, CreditsObservable &credits, std::string url, const wxString &title)
    : wxPanel(parent), credits_(credits), url_(std::move(url)), timer_(this) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    content_ = new wxTextCtrl(this, wxID_ANY, {}, wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY | wxTE_MULTILINE | wxTE_BESTWRAP | wxBORDER_NONE);
    Theme::Apply(this);
    content_->SetBackgroundColour(GetBackgroundColour());
    content_->SetName(title);
    content_->SetFont(wxFontInfo(content_->GetFont().GetPointSize()).Family(wxFONTFAMILY_TELETYPE));
    layout->Add(content_, 1, wxEXPAND | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    credits_.LoadLicense(url_);
    Bind(wxEVT_TIMER, [this](wxTimerEvent &) {
        UpdateContent();
    });
    timer_.Start(100);
    UpdateContent();
}
void LicenseView::UpdateContent() {
    const auto state = credits_.License(url_);
    const auto text = state.loading ? Localized(StringKey::GlobalNounsLoading) : state.failed
        ? Localized(StringKey::ErrorsAppOther) : wxString::FromUTF8(state.text);
    if (content_->GetValue() != text) content_->ChangeValue(text);
    if (!state.loading) timer_.Stop();
}
}
