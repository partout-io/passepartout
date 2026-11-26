// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "LicenseView.h"
#include "../../strings/Strings.h"

namespace Passepartout {
LicenseView::LicenseView(wxWindow *parent, CreditsObservable &credits, std::string url, const wxString &title)
    : ThemeLongContent(parent, title, {}), credits_(credits), url_(std::move(url)), observer_([this] { UpdateContent(); }) {
    observer_.Observe(credits_.changes);
    credits_.LoadLicense(url_);
    UpdateContent();
}

void LicenseView::UpdateContent() {
    const auto state = credits_.License(url_);
    const auto text = state.loading ? Localized(StringKey::GlobalNounsLoading) : state.operation_failed
        ? Localized(StringKey::ErrorsAppOther) : wxString::FromUTF8(state.text);
    SetContent(text);
}
}
