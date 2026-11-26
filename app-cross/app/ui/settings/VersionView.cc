// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "VersionView.h"
#include "ChangelogView.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
VersionView::VersionView(wxWindow *parent, VersionObservable &version, const CrossConstantsType::App &app,
                         const Models::AppConstants_github &github, SettingsPresentation present
)
    : ThemeDetailView(parent, Presentation::Centered) {
    const auto name = wxString::FromUTF8(app.name);
    Logo();
    Section(name);
    Message(wxString::FromUTF8(app.version_number));
    auto author = Localized(StringKey::ViewsVersionExtra);
    author.Replace("%@", name, false);
    author.Replace("%@", wxString::FromUTF8(Strings::Unlocalized::AuthorName), false);
    Message(author);
    ContentLink(wxString(Strings::Unlocalized::Changelog).Upper(), [present, &version, app, github] {
        present(Strings::Unlocalized::Changelog, [&version, app, github](wxWindow *parent) {
            return new ChangelogView(parent, version, app, github);
        });
    });
    Finish();
}
}
