// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ThemeNavigationHeader.h"
#include "Theme.h"
#include "../strings/Strings.h"

namespace Passepartout {
ThemeNavigationHeader::ThemeNavigationHeader(wxWindow *parent, std::function<void()> back)
    : wxPanel(parent), backAction_(std::move(back)) {
    auto *layout = new wxBoxSizer(wxHORIZONTAL);
    back_ = new wxButton(this, wxID_BACKWARD, Localized(StringKey::GlobalActionsBack));
    back_->Enable(false);
    layout->Add(back_, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, Theme::Spacing(this));
    title_ = new wxStaticText(this, wxID_ANY, wxString());
    title_->SetFont(title_->GetFont().Bold());
    layout->Add(title_, 1, wxALIGN_CENTER_VERTICAL);
    SetSizer(layout);
    back_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        if (back_->IsEnabled()) backAction_();
    });
}
void ThemeNavigationHeader::Update(const wxString &title, bool canGoBack) {
    if (title_->GetLabel() != title) {
        title_->SetLabel(title);
        Layout();
    }
    back_->Enable(canGoBack);
}
void ThemeNavigationHeader::HandleKey(wxKeyEvent &event, const std::function<void()> &dismiss) {
    if (event.GetKeyCode() == WXK_ESCAPE) {
        dismiss();
        return;
    }
    if (event.GetKeyCode() == WXK_LEFT && event.GetModifiers() == wxMOD_ALT) {
        if (back_->IsEnabled()) backAction_();
        return;
    }
    event.Skip();
}
}
