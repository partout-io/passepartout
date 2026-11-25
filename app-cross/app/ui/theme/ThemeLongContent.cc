// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ThemeLongContent.h"
#include "Theme.h"
#include <algorithm>

namespace Passepartout {
ThemeLongContent::ThemeLongContent(wxWindow *parent, const wxString &title, const wxString &content)
    : wxPanel(parent) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    text_ = new wxTextCtrl(this, wxID_ANY, content, wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY | wxTE_MULTILINE | wxTE_BESTWRAP);
    Theme::Monospace(text_);
    text_->SetName(title);
    layout->Add(text_, 1, wxEXPAND | wxALL, Theme::Spacing(this));
    SetSizer(layout);
}

void ThemeLongContent::SetContent(const wxString &content) {
    if (text_->GetValue() == content) return;
    long from = 0, to = 0;
    text_->GetSelection(&from, &to);
    text_->ChangeValue(content);
    const auto end = text_->GetLastPosition();
    text_->SetSelection(std::min(from, end), std::min(to, end));
}
}
