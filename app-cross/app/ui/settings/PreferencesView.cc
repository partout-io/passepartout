// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PreferencesView.h"
#include "../extensions/Presentation.h"

namespace Passepartout {
PreferencesView::PreferencesView(wxWindow *parent, UserPreferencesObservable &preferences) : ThemeDetailView(parent, Presentation::Plain) {
    Section(Localized(StringKey::GlobalNounsGeneral));
    if (preferences.HasLoadError()) Message(Localized(StringKey::ErrorsAppOther));
    auto *dns = Toggle(Localized(StringKey::ViewsPreferencesDnsFallsBack),
        Localized(StringKey::ViewsPreferencesDnsFallsBackFooter), preferences.Snapshot().dnsFallsBack);
    Message(Localized(StringKey::ViewsPreferencesNextConnection), TextStyle::Secondary);
    dns->Bind(wxEVT_CHECKBOX, [this, dns, &preferences](wxCommandEvent &) {
        try {
            preferences.SetDNSFallback(dns->GetValue());
        } catch (...) {
            dns->SetValue(preferences.Snapshot().dnsFallsBack);
            PresentError(this);
        }
    });
    Finish();
}
}
