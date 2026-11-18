// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "CreditsView.h"
#include "LicenseView.h"
#include "../LongContentView.h"
#include "../../strings/Strings.h"
#include <wx/uilocale.h>

namespace Passepartout {
CreditsView::CreditsView(wxWindow *parent, CreditsObservable &credits, SettingsPresentation present) : ThemeDetailView(parent) {
    if (credits.HasLoadError()) {
        Message(Localized(StringKey::ErrorsAppOther));
        Finish();
        return;
    }
    const auto &state = credits.Snapshot();
    Section(Localized(StringKey::ViewsSettingsCreditsLicenses));
    for (const auto &license : state.licenses) {
        const auto title = wxString::FromUTF8(license.name);
        ContentLink(title, [present, title, &credits, url = license.licenseURL] {
            present(title, [&credits, url, title](wxWindow *parent) {
                return new LicenseView(parent, credits, url, title);
            });
        }, wxString::FromUTF8(license.licenseName));
    }
    Section(Localized(StringKey::ViewsSettingsCreditsNotices));
    for (const auto &notice : state.notices) {
        const auto title = wxString::FromUTF8(notice.name);
        ContentLink(title, [present, title, content = notice.message] {
            present(title, [title, content](wxWindow *parent) {
                return new LongContentView(parent, title, wxString::FromUTF8(content));
            });
        });
    }
    Section(Localized(StringKey::ViewsSettingsCreditsTranslations));
    for (const auto &[language, authors] : state.translations) {
        wxString text;
        for (const auto &author : authors) {
            if (!text.empty()) text += '\n';
            text += wxString::FromUTF8(author);
        }
        const auto *info = wxUILocale::FindLanguageInfo(wxLocaleIdent::FromTag(wxString::FromUTF8(language)));
        Field(info ? wxGetTranslation(info->Description) : wxString::FromUTF8(language), text);
    }
    Finish();
}
}
