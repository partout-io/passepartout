// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "VersionView.h"
#include "ChangelogView.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
VersionView::VersionView(wxWindow *parent, VersionObservable &version, const wxString &name, SettingsPresentation present)
    : ThemeDetailView(parent, Presentation::Centered) {
    const auto state = version.Snapshot();
    Logo();
    Section(name);
    Message(wxString::FromUTF8(state.current));
    auto author = Localized(StringKey::ViewsVersionExtra);
    author.Replace("%@", name, false);
    author.Replace("%@", wxString::FromUTF8(Strings::Unlocalized::AuthorName), false);
    Message(author);
    ContentLink(wxString(Strings::Unlocalized::Changelog).Upper(), [present, &version] {
        present(Strings::Unlocalized::Changelog, [&version](wxWindow *parent) {
            return new ChangelogView(parent, version);
        });
    });
    Finish();
}
}
