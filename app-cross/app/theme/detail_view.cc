// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "detail_view.h"

namespace Passepartout {
ThemeDetailView::ThemeDetailView(wxWindow *parent)
    : wxScrolledWindow(parent, wxID_ANY), layout_(new wxBoxSizer(wxVERTICAL)) {
    SetScrollRate(0, FromDIP(12));
    SetSizer(layout_);
    Theme::Apply(this);
}
void ThemeDetailView::Section(const wxString &title) {
    auto *label = new wxStaticText(this, wxID_ANY, title);
    label->SetFont(label->GetFont().Bold());
    layout_->Add(label, 0, wxEXPAND | wxALL, Theme::Spacing(this));
}
wxTextCtrl *ThemeDetailView::Field(const wxString &title, const wxString &value) {
    if (value.empty()) return nullptr;
    auto *row = new wxBoxSizer(wxVERTICAL);
    row->Add(new wxStaticText(this, wxID_ANY, title), 0, wxEXPAND);
    const bool multiline = value.Contains('\n');
    auto *text = new wxTextCtrl(this, wxID_ANY, value, wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY | (multiline ? wxTE_MULTILINE | wxTE_BESTWRAP : 0));
    text->SetName(title);
    if (multiline) text->SetMinSize(FromDIP(wxSize(-1, 80)));
    row->Add(text, 0, wxEXPAND | wxTOP, FromDIP(4));
    layout_->Add(row, 0, wxEXPAND | wxLEFT | wxRIGHT | wxBOTTOM, Theme::Spacing(this));
    return text;
}
wxButton *ThemeDetailView::Action(const wxString &title, std::function<void()> action) {
    auto *button = new wxButton(this, wxID_ANY, title);
    button->Bind(wxEVT_BUTTON, [action = std::move(action)](wxCommandEvent &) {
        action();
    });
    layout_->Add(button, 0, wxEXPAND | wxLEFT | wxRIGHT | wxBOTTOM, Theme::Spacing(this));
    return button;
}
wxTextCtrl *ThemeDetailView::TextField(const wxString &title, const wxString &value, long style) {
    layout_->Add(new wxStaticText(this, wxID_ANY, title), 0, wxLEFT | wxRIGHT, Theme::Spacing(this));
    auto *text = new wxTextCtrl(this, wxID_ANY, value, wxDefaultPosition, wxDefaultSize, style);
    text->SetName(title);
    layout_->Add(text, 0, wxEXPAND | wxLEFT | wxRIGHT | wxBOTTOM, Theme::Spacing(this));
    return text;
}
void ThemeDetailView::Finish() {
    Layout();
    FitInside();
}
wxCheckBox *ThemeDetailView::Toggle(const wxString &title, const wxString &support, bool checked) {
    auto *control = new wxCheckBox(this, wxID_ANY, title);
    control->SetValue(checked);
    layout_->Add(control, 0, wxEXPAND | wxALL, Theme::Spacing(this));
    if (!support.empty()) Message(support);
    return control;
}
void ThemeDetailView::Message(const wxString &text) {
    auto *label = new wxStaticText(this, wxID_ANY, text);
    label->Wrap(FromDIP(480));
    layout_->Add(label, 0, wxEXPAND | wxLEFT | wxRIGHT | wxBOTTOM, Theme::Spacing(this));
}
void ThemeDetailView::Logo() {
    const auto icon = Theme::AppIcon(this, 64);
    if (icon.IsOk()) layout_->Add(new wxStaticBitmap(this, wxID_ANY, wxBitmap(icon)),
        0, wxALIGN_CENTER | wxALL, Theme::Spacing(this));
}
}
