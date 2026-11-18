// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ProfileView.h"
#include "../../theme/Theme.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
ProfileView::ProfileView(wxWindow *parent, std::shared_ptr<ProfileEditor> editor,
    std::function<void()> changed)
    : ThemeDetailView(parent, Presentation::Form) {
    const auto draft = editor->Snapshot().draft;
    Section(Localized(StringKey::GlobalNounsProfile));
    auto *name = TextField(Localized(StringKey::GlobalNounsName), wxString::FromUTF8(draft.name));
    name->Bind(wxEVT_TEXT, [editor, name, changed](wxCommandEvent &) {
        editor->Rename(name->GetValue().ToStdString(wxConvUTF8));
        changed();
    });
    CopiableField(Strings::Unlocalized::UUID, wxString::FromUTF8(draft.id));
    Finish();
}
}
