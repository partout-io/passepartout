// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ProfileView.h"
#include "../../theme/Theme.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
ProfileView::ProfileView(wxWindow *parent, std::shared_ptr<ProfileEditor> editor,
    std::function<void()> changed)
    : wxPanel(parent) {
    const auto draft = editor->Snapshot().draft;
    const auto spacing = Theme::Spacing(this);
    auto *layout = new wxBoxSizer(wxVERTICAL);

    auto *nameRow = new wxBoxSizer(wxHORIZONTAL);
    nameRow->Add(new wxStaticText(this, wxID_ANY, Localized(StringKey::GlobalNounsName)),
        0, wxALIGN_CENTER_VERTICAL | wxRIGHT, spacing);
    auto *name = new wxTextCtrl(this, wxID_ANY, wxString::FromUTF8(draft.name));
    name->SetName(Localized(StringKey::GlobalNounsName));
    nameRow->Add(name, 1, wxALIGN_CENTER_VERTICAL);
    layout->Add(nameRow, 0, wxEXPAND | wxALL, spacing);
    name->Bind(wxEVT_TEXT, [editor, name, changed](wxCommandEvent &) {
        editor->Rename(name->GetValue().ToStdString(wxConvUTF8));
        changed();
    });

    layout->AddStretchSpacer();

    const auto id = wxString::FromUTF8(draft.id);
    auto *footer = new wxBoxSizer(wxHORIZONTAL);
    footer->Add(new wxStaticText(this, wxID_ANY, Strings::Unlocalized::UUID),
        0, wxALIGN_CENTER_VERTICAL | wxRIGHT, spacing);
    auto *value = new wxTextCtrl(this, wxID_ANY, id, wxDefaultPosition, wxDefaultSize, wxTE_READONLY | wxBORDER_NONE | wxTE_RIGHT);
    value->SetBackgroundColour(GetBackgroundColour());
    value->SetName(Strings::Unlocalized::UUID);
    footer->Add(value, 1, wxALIGN_CENTER_VERTICAL);
    layout->Add(footer, 0, wxEXPAND | wxALL, spacing);
    SetSizer(layout);
}
}
