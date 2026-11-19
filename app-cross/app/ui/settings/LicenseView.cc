// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "LicenseView.h"
#include "../../strings/Strings.h"

namespace Passepartout {
LicenseView::LicenseView(wxWindow *parent, CreditsObservable &credits, std::string url, const wxString &title)
    : ThemeLongContent(parent, title, {}), credits_(credits), url_(std::move(url)), timer_(this) {
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
    SetContent(text);
    if (!state.loading) timer_.Stop();
}
}
