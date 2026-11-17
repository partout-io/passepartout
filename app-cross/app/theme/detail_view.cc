// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "detail_view.h"
#include <wx/statline.h>

namespace Passepartout {
ThemeDetailView::ThemeDetailView(wxWindow *parent)
    : wxScrolledWindow(parent, wxID_ANY), layout_(new wxBoxSizer(wxVERTICAL)) {
    SetScrollRate(0, FromDIP(12));
    SetSizer(layout_);
    Theme::Apply(this);
}
void ThemeDetailView::Section(const wxString &title) {
    list_ = nullptr;
    auto *label = new wxStaticText(this, wxID_ANY, title);
    label->SetFont(label->GetFont().Bold());
    layout_->Add(label, 0, wxEXPAND | wxALL, Theme::Spacing(this));
}
wxBoxSizer *ThemeDetailView::Row(const wxString &title) {
    list_ = nullptr;
    auto *row = new wxBoxSizer(wxHORIZONTAL);
    auto *caption = new wxStaticText(this, wxID_ANY, title);
    caption->SetMinSize(FromDIP(wxSize(150, -1)));
    row->Add(caption, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, FromDIP(20));
    layout_->Add(row, 0, wxEXPAND | wxALL, Theme::Spacing(this));
    layout_->Add(new wxStaticLine(this), 0, wxEXPAND | wxLEFT | wxRIGHT, Theme::Spacing(this));
    return row;
}
ThemeDetailList *ThemeDetailView::List() {
    if (!list_) {
        list_ = new ThemeDetailList(this);
        layout_->Add(list_, 0, wxEXPAND | wxLEFT | wxRIGHT, Theme::Spacing(this));
    }
    return list_;
}
void ThemeDetailView::Field(const wxString &title, const wxString &value, bool monospace) {
    if (!value.empty()) List()->Append(title, value, {}, true, monospace);
}
void ThemeDetailView::Navigate(const wxString &title, std::function<void()> action,
    const wxString &value, bool enabled) {
    List()->Append(title, value, std::move(action), enabled);
}
wxButton *ThemeDetailView::Action(const wxString &title, std::function<void()> action) {
    list_ = nullptr;
    auto *button = new wxButton(this, wxID_ANY, title);
    button->Bind(wxEVT_BUTTON, [action = std::move(action)](wxCommandEvent &) {
        action();
    });
    layout_->Add(button, 0, wxALIGN_RIGHT | wxALL, Theme::Spacing(this));
    return button;
}
wxTextCtrl *ThemeDetailView::TextField(const wxString &title, const wxString &value, long style) {
    auto *row = Row(title);
    auto *text = new wxTextCtrl(this, wxID_ANY, value, wxDefaultPosition, wxDefaultSize, style);
    text->SetName(title);
    row->Add(text, 1, wxALIGN_CENTER_VERTICAL);
    return text;
}
void ThemeDetailView::Finish() {
    Layout();
    FitInside();
}
wxCheckBox *ThemeDetailView::Toggle(const wxString &title, const wxString &support, bool checked) {
    list_ = nullptr;
    auto *row = new wxBoxSizer(wxHORIZONTAL);
    auto *captions = new wxBoxSizer(wxVERTICAL);
    captions->Add(new wxStaticText(this, wxID_ANY, title), 0, wxEXPAND);
    if (!support.empty()) {
        auto *description = new wxStaticText(this, wxID_ANY, support);
        description->Wrap(FromDIP(440));
        captions->Add(description, 0, wxEXPAND | wxTOP, FromDIP(4));
    }
    row->Add(captions, 1, wxALIGN_CENTER_VERTICAL | wxRIGHT, FromDIP(20));
    auto *control = new wxCheckBox(this, wxID_ANY, {});
    control->SetName(title);
    control->SetValue(checked);
    row->Add(control, 0, wxALIGN_CENTER_VERTICAL);
    layout_->Add(row, 0, wxEXPAND | wxALL, Theme::Spacing(this));
    return control;
}
void ThemeDetailView::Message(const wxString &text) {
    list_ = nullptr;
    auto *label = new wxStaticText(this, wxID_ANY, text);
    label->Wrap(FromDIP(480));
    layout_->Add(label, 0, wxEXPAND | wxLEFT | wxRIGHT | wxBOTTOM, Theme::Spacing(this));
}
void ThemeDetailView::Logo() {
    list_ = nullptr;
    const auto icon = Theme::AppIcon(this, 64);
    if (icon.IsOk()) layout_->Add(new wxStaticBitmap(this, wxID_ANY, wxBitmap(icon)),
        0, wxALIGN_CENTER | wxALL, Theme::Spacing(this));
}
}
