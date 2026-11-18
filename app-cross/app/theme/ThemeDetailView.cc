// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ThemeDetailView.h"
#include "ThemeContentLink.h"
#include <wx/statline.h>
#include <wx/statbox.h>

namespace Passepartout {
ThemeDetailView::ThemeDetailView(wxWindow *parent, Presentation presentation)
    : wxScrolledWindow(parent, wxID_ANY), layout_(new wxBoxSizer(wxVERTICAL)),
      presentation_(presentation), contentParent_(this), section_(layout_) {
    SetScrollRate(0, FromDIP(12));
    SetSizer(layout_);
}
void ThemeDetailView::Section(const wxString &title) {
    if (IsForm()) {
        auto *box = new wxStaticBoxSizer(wxVERTICAL, this, title);
        layout_->Add(box, 0, wxEXPAND | wxALL, Theme::Spacing(this));
        contentParent_ = box->GetStaticBox();
        section_ = box;
        formRows_ = nullptr;
        return;
    }
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
    if (presentation_ == Presentation::Plain) {
        auto *row = new wxBoxSizer(wxVERTICAL);
        row->Add(new wxStaticText(this, wxID_ANY, title), 0, wxBOTTOM, Theme::Spacing(this) / 2);
        row->Add(new wxStaticText(this, wxID_ANY, value), 0, wxEXPAND);
        layout_->Add(row, 0, wxEXPAND | wxALL, Theme::Spacing(this));
        return;
    }
    if (IsForm()) {
        if (value.empty()) return;
        auto *rows = FormRows();
        rows->Add(new wxStaticText(contentParent_, wxID_ANY, title), 0, wxALIGN_CENTER_VERTICAL);
        rows->Add(Value(value, monospace), 1, wxEXPAND | wxALIGN_CENTER_VERTICAL);
        return;
    }
    if (!value.empty()) Row(title)->Add(Value(value, monospace), 1, wxALIGN_CENTER_VERTICAL);
}
void ThemeDetailView::CopiableField(const wxString &title, const wxString &value, bool monospace) {
    auto *text = TextField(title, value, wxTE_READONLY);
    if (monospace) Theme::Monospace(text);
}
void ThemeDetailView::ContentLink(const wxString &title, std::function<void()> action,
    const wxString &value, bool enabled) {
    if (IsForm()) {
        auto *rows = FormRows();
        auto *link = new ThemeContentLink(contentParent_, title, std::move(action));
        link->Enable(enabled);
        rows->Add(link, 0, wxALIGN_CENTER_VERTICAL);
        rows->Add(Value(value), 1, wxEXPAND | wxALIGN_CENTER_VERTICAL);
        return;
    }
    if (presentation_ == Presentation::Plain) {
        auto *row = new wxBoxSizer(wxHORIZONTAL);
        auto *link = new ThemeContentLink(this, title, std::move(action));
        link->Enable(enabled);
        row->Add(link, 0, wxALIGN_CENTER_VERTICAL);
        if (!value.empty()) {
            row->Add(new wxStaticText(this, wxID_ANY, value), 1,
                wxALIGN_CENTER_VERTICAL | wxLEFT, Theme::Spacing(this));
        }
        layout_->Add(row, 0, wxEXPAND | wxALL, Theme::Spacing(this));
        return;
    }
    List()->Append(title, value, std::move(action), enabled);
}
void ThemeDetailView::ExternalLink(const wxString &title, std::function<void()> action) {
    list_ = nullptr;
    auto *link = new ThemeContentLink(this, title, std::move(action));
    layout_->Add(link, 0, wxALL, Theme::Spacing(this));
}
void ThemeDetailView::LongContent(const wxString &title, const wxString &preview,
    std::function<void()> action) {
    ContentLink(title, std::move(action), preview.BeforeFirst('\n'));
}
wxFlexGridSizer *ThemeDetailView::FormRows() {
    if (!formRows_) {
        formRows_ = new wxFlexGridSizer(2, Theme::Spacing(this), 2 * Theme::Spacing(this));
        formRows_->AddGrowableCol(1);
        section_->Add(formRows_, 0, wxEXPAND | wxALL, Theme::Spacing(this));
    }
    return formRows_;
}
wxStaticText *ThemeDetailView::Value(const wxString &value, bool monospace) {
    auto *text = new wxStaticText(contentParent_, wxID_ANY, value.BeforeFirst('\n'),
        wxDefaultPosition, wxDefaultSize, wxST_ELLIPSIZE_END);
    if (monospace) Theme::Monospace(text);
    text->SetMinSize(wxSize(GetCharWidth() * 12, text->GetBestSize().y));
    text->SetName(value);
    return text;
}
void ThemeDetailView::Items(const wxString &title, const std::vector<wxString> &values) {
    for (const auto &value : values) CopiableField(title, value);
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
    if (title.empty()) {
        auto *text = new wxTextCtrl(contentParent_, wxID_ANY, value, wxDefaultPosition, wxDefaultSize, style);
        text->SetName(value);
        section_->Add(text, 0, wxEXPAND | wxALL, Theme::Spacing(this));
        formRows_ = nullptr;
        return text;
    }
    if (IsForm()) {
        auto *rows = FormRows();
        rows->Add(new wxStaticText(contentParent_, wxID_ANY, title), 0, wxALIGN_CENTER_VERTICAL);
        auto *text = new wxTextCtrl(contentParent_, wxID_ANY, value, wxDefaultPosition, wxDefaultSize, style);
        text->SetName(title);
        rows->Add(text, 1, wxEXPAND | wxALIGN_CENTER_VERTICAL);
        return text;
    }
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
