// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ThemeButtonRow.h"
#include <algorithm>

namespace Passepartout {
ThemeButtonRow::ThemeButtonRow(wxWindow *parent, const wxString &title,
    std::function<void()> action, const wxString &explanation) : wxBoxSizer(wxHORIZONTAL) {
    button_ = new wxButton(parent, wxID_ANY, title);
    button_->Bind(wxEVT_BUTTON, [action = std::move(action)](wxCommandEvent &) {
        action();
    });
    Add(button_, 0, wxALIGN_CENTER_VERTICAL);
    if (explanation.empty()) return;
    explanation_ = new wxStaticText(parent, wxID_ANY, explanation,
        wxDefaultPosition, wxDefaultSize, wxST_NO_AUTORESIZE);
    explanation_->SetMinSize(wxSize(1, explanation_->GetBestSize().y));
    Theme::SecondaryText(explanation_);
    Add(explanation_, 1, wxALIGN_CENTER_VERTICAL | wxLEFT,
        Theme::Spacing(parent, Theme::Space::Columns));
}
void ThemeButtonRow::AlignButtons(const std::vector<wxButton *> &buttons) {
    int width = 0;
    for (auto *button : buttons) {
        button->SetMinSize(wxDefaultSize);
        button->InvalidateBestSize();
        width = std::max(width, button->GetBestSize().x);
    }
    for (auto *button : buttons) {
        button->SetMinSize(wxSize(width, button->GetBestSize().y));
    }
}

}
