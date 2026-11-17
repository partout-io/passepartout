// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "version_view.h"
#include "../long_content_view.h"
#include "../../strings/strings.h"
#include "../../strings/unlocalized.h"

namespace Passepartout {
VersionView::VersionView(wxWindow *parent, VersionObservable &version, const wxString &name, SettingsNavigation navigate)
    : ThemeDetailView(parent) {
    const auto state = version.Snapshot();
    Logo();
    Section(name);
    Message(wxString::FromUTF8(state.current));
    auto author = Localized(StringKey::ViewsVersionExtra);
    author.Replace("%@", name, false);
    author.Replace("%@", wxString::FromUTF8(Strings::Unlocalized::AuthorName), false);
    Message(author);
    Navigate(Strings::Unlocalized::Changelog, [navigate, content = state.changelog] {
        navigate(Strings::Unlocalized::Changelog, [content](wxWindow *parent) {
            return new LongContentView(parent, Strings::Unlocalized::Changelog, wxString::FromUTF8(content));
        });
    });
    Finish();
}
}
