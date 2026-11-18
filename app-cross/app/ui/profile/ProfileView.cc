// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ProfileView.h"
#include "../Presentation.h"
#include "../../theme/Theme.h"
#include "../../strings/Unlocalized.h"
#include <wx/clipbrd.h>
#include <wx/dataobj.h>

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
    footer->AddStretchSpacer();
    auto *value = new wxStaticText(this, wxID_ANY, id);
    footer->Add(value, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, spacing);
    auto *copy = new wxButton(this, wxID_COPY);
    copy->Bind(wxEVT_BUTTON, [this, id](wxCommandEvent &) {
        if (!wxTheClipboard->Open()) {
            PresentError(this);
            return;
        }
        const bool copied = wxTheClipboard->SetData(new wxTextDataObject(id));
        wxTheClipboard->Close();
        if (!copied) PresentError(this);
    });
    footer->Add(copy, 0, wxALIGN_CENTER_VERTICAL);
    layout->Add(footer, 0, wxEXPAND | wxALL, spacing);
    SetSizer(layout);
}
}
