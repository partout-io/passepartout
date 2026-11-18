// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "VersionView.h"
#include "../../theme/ThemeLongContent.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
VersionView::VersionView(wxWindow *parent, VersionObservable &version, const wxString &name, SettingsPresentation present)
    : ThemeDetailView(parent, Presentation::Plain) {
    const auto state = version.Snapshot();
    Logo();
    Section(name);
    Message(wxString::FromUTF8(state.current));
    auto author = Localized(StringKey::ViewsVersionExtra);
    author.Replace("%@", name, false);
    author.Replace("%@", wxString::FromUTF8(Strings::Unlocalized::AuthorName), false);
    Message(author);
    ContentLink(Strings::Unlocalized::Changelog, [present, content = state.changelog] {
        present(Strings::Unlocalized::Changelog, [content](wxWindow *parent) {
            return new ThemeLongContent(parent, Strings::Unlocalized::Changelog, wxString::FromUTF8(content));
        });
    });
    Finish();
    SetMinSize(GetSizer()->GetMinSize());
}
}
