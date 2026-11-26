// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PreferencesView.h"
#include "../platform/Presentation.h"

namespace Passepartout {
PreferencesView::PreferencesView(wxWindow *parent, UserPreferencesObservable &preferences) : ThemeDetailView(parent, Presentation::Plain), preferences_(preferences), observer_([this] { UpdateContent(); }) {
    Section(Localized(StringKey::GlobalNounsGeneral));
    if (preferences.HasLoadError()) Message(Localized(StringKey::ErrorsAppOther));
    dns_ = Toggle(Localized(StringKey::ViewsPreferencesDnsFallsBack),
        Localized(StringKey::ViewsPreferencesDnsFallsBackFooter), false
    );
    dns_->Bind(wxEVT_CHECKBOX, [this](wxCommandEvent &) {
        try {
            preferences_.SetDNSFallback(dns_->GetValue());
        } catch (...) {
            UpdateContent();
            PresentError(this);
        }
    });
    observer_.Observe(preferences_.changes);
    UpdateContent();
    Finish();
}

void PreferencesView::UpdateContent() {
    dns_->SetValue(preferences_.Snapshot().dnsFallsBack);
}
}
