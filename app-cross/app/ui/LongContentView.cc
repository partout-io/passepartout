// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "LongContentView.h"
#include "../theme/Theme.h"

namespace Passepartout {
LongContentView::LongContentView(wxWindow *parent, const wxString &title, const wxString &content)
    : wxPanel(parent) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    auto *text = new wxTextCtrl(this, wxID_ANY, content, wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY | wxTE_MULTILINE | wxTE_BESTWRAP);
    Theme::Monospace(text);
    text->SetName(title);
    layout->Add(text, 1, wxEXPAND | wxALL, Theme::Spacing(this));
    SetSizer(layout);
}
}
