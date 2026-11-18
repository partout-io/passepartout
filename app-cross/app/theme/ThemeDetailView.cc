// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ThemeDetailView.h"
#include "ThemeContentLink.h"
#include "../strings/Strings.h"
#include <wx/statline.h>
#include <wx/statbox.h>

namespace Passepartout {
ThemeDetailView::ThemeDetailView(wxWindow *parent, Presentation presentation)
    : wxScrolledWindow(parent, wxID_ANY), layout_(new wxBoxSizer(wxVERTICAL)),
      presentation_(presentation), contentParent_(this), section_(layout_) {
    SetScrollRate(0, Theme::Spacing(this));
    SetSizer(layout_);
    Bind(wxEVT_SIZE, [this](wxSizeEvent &event) {
        if (!wrapPending_) {
            wrapPending_ = true;
            CallAfter([this] {
                wrapPending_ = false;
                Rewrap();
            });
        }
        event.Skip();
    });
}
void ThemeDetailView::Section(const wxString &title) {
    if (IsForm() || presentation_ == Presentation::Plain) {
        auto *box = new wxStaticBoxSizer(wxVERTICAL, this, title);
        layout_->Add(box, 0, wxEXPAND | wxALL, Theme::Spacing(this));
        contentParent_ = box->GetStaticBox();
        section_ = box;
        formRows_ = nullptr;
        return;
    }
    list_ = nullptr;
    auto *label = new wxStaticText(this, wxID_ANY, title);
    auto font = label->GetFont().Bold();
    if (presentation_ == Presentation::Centered) font = font.Scaled(1.3f);
    label->SetFont(font);
    if (presentation_ == Presentation::Plain) {
        layout_->AddSpacer(Theme::Spacing(this));
        layout_->Add(label, 0, wxEXPAND | wxLEFT | wxRIGHT, Theme::Spacing(this));
        layout_->AddSpacer(Theme::Spacing(this, Theme::Space::SectionContent));
        return;
    }
    layout_->Add(label, 0, (presentation_ == Presentation::Centered ? wxALIGN_CENTER_HORIZONTAL : wxEXPAND) | wxALL,
        presentation_ == Presentation::Centered ? Theme::Spacing(this, Theme::Space::SectionContent) : Theme::Spacing(this));
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
        auto *rows = FormRows();
        auto *caption = WrappingText(title);
        caption->SetMinSize(wxSize(GetCharWidth() * 20, caption->GetBestSize().y));
        rows->Add(caption, 0, wxEXPAND);
        rows->Add(WrappingText(value), 1, wxEXPAND);
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
    auto *text = TextField(title, value, wxTE_READONLY | wxBORDER_NONE | wxTE_RIGHT);
    text->SetBackgroundColour(text->GetParent()->GetBackgroundColour());
    if (monospace) Theme::Monospace(text);
}
void ThemeDetailView::ContentLink(const wxString &title, std::function<void()> action,
    const wxString &value, bool enabled) {
    if (IsForm()) {
        auto *rows = FormRows();
        rows->Add(new wxStaticText(contentParent_, wxID_ANY, title), 0, wxALIGN_CENTER_VERTICAL);
        const auto label = value.empty() ? Localized(StringKey::GlobalActionsEdit) : value;
        auto *link = new ThemeContentLink(contentParent_, label, std::move(action));
        link->SetName(title);
        link->Enable(enabled);
        rows->Add(link, 0, wxALIGN_RIGHT | wxALIGN_CENTER_VERTICAL);
        return;
    }
    if (presentation_ == Presentation::Plain || presentation_ == Presentation::Centered) {
        auto *row = new wxBoxSizer(wxHORIZONTAL);
        auto *link = new ThemeContentLink(contentParent_, title, std::move(action));
        link->Enable(enabled);
        row->Add(link, 0, wxALIGN_CENTER_VERTICAL);
        if (!value.empty()) {
            row->Add(new wxStaticText(contentParent_, wxID_ANY, value, wxDefaultPosition, wxDefaultSize, wxALIGN_RIGHT), 1,
                wxALIGN_CENTER_VERTICAL | wxLEFT, Theme::Spacing(this));
        }
        if (presentation_ == Presentation::Plain) {
            section_->Add(row, 0, wxEXPAND | wxLEFT | wxRIGHT, Theme::Spacing(this));
            section_->AddSpacer(Theme::Spacing(this, Theme::Space::Row));
        } else {
            layout_->Add(row, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, Theme::Spacing(this, Theme::Space::SectionContent));
        }
        return;
    }
    List()->Append(title, value, std::move(action), enabled);
}
void ThemeDetailView::ExternalLink(const wxString &title, std::function<void()> action) {
    list_ = nullptr;
    auto *link = new ThemeContentLink(contentParent_, title, std::move(action));
    section_->Add(link, 0, wxLEFT | wxRIGHT, Theme::Spacing(this));
    section_->AddSpacer(Theme::Spacing(this, Theme::Space::Row));
}
void ThemeDetailView::LongContent(const wxString &title, const wxString &preview,
    std::function<void()> action) {
    ContentLink(title, std::move(action), preview.BeforeFirst('\n'));
}
wxFlexGridSizer *ThemeDetailView::FormRows() {
    if (!formRows_) {
        formRows_ = new wxFlexGridSizer(2, Theme::Spacing(this, Theme::Space::Row), Theme::Spacing(this, Theme::Space::Columns));
        formRows_->AddGrowableCol(1);
        section_->Add(formRows_, 0, wxEXPAND | wxALL, Theme::Spacing(this, Theme::Space::SectionContent));
    }
    return formRows_;
}
wxStaticText *ThemeDetailView::Value(const wxString &value, bool monospace) {
    auto *text = new wxStaticText(contentParent_, wxID_ANY, value.BeforeFirst('\n'),
        wxDefaultPosition, wxDefaultSize, wxST_ELLIPSIZE_END | wxALIGN_RIGHT);
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
        section_->Add(text, 0, wxEXPAND | wxLEFT | wxRIGHT, Theme::Spacing(this));
        section_->AddSpacer(Theme::Spacing(this, Theme::Space::Row));
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
wxStaticText *ThemeDetailView::WrappingText(const wxString &text) {
    auto *label = new wxStaticText(contentParent_, wxID_ANY, text,
        wxDefaultPosition, wxDefaultSize, wxST_NO_AUTORESIZE);
    label->SetMinSize(wxSize(1, label->GetBestSize().y));
    wrapped_.push_back({label, text});
    return label;
}
void ThemeDetailView::Rewrap() {
    bool changed = false;
    for (auto &entry : wrapped_) {
        const int width = entry.label->GetSize().x;
        if (width <= 1 || width == entry.width) continue;
        entry.width = width;
        entry.label->SetLabel(entry.text);
        entry.label->Wrap(width);
        entry.label->InvalidateBestSize();
        entry.label->SetMinSize(wxSize(entry.label->GetMinSize().x, entry.label->GetBestSize().y));
        changed = true;
    }
    if (changed) {
        Layout();
        FitInside();
    }
}
void ThemeDetailView::Finish() {
    Layout();
    FitInside();
}
wxCheckBox *ThemeDetailView::Toggle(const wxString &title, const wxString &support, bool checked) {
    list_ = nullptr;
    auto *row = new wxBoxSizer(wxHORIZONTAL);
    auto *captions = new wxBoxSizer(wxVERTICAL);
    captions->Add(WrappingText(title), 0, wxEXPAND);
    if (!support.empty()) {
        auto *subtitle = WrappingText(support);
        Theme::SecondaryText(subtitle);
        captions->Add(subtitle, 0, wxEXPAND | wxTOP,
            Theme::Spacing(this, Theme::Space::Row));
    }
    row->Add(captions, 1, wxALIGN_CENTER_VERTICAL | wxRIGHT, Theme::Spacing(this, Theme::Space::Columns));
    auto *control = new wxCheckBox(contentParent_, wxID_ANY, {});
    control->SetName(title);
    control->SetValue(checked);
    row->Add(control, 0, wxALIGN_CENTER_VERTICAL);
    section_->Add(row, 0, wxEXPAND | wxALL, Theme::Spacing(this, Theme::Space::SectionContent));
    return control;
}
void ThemeDetailView::Message(const wxString &text, TextStyle style) {
    list_ = nullptr;
    if (presentation_ != Presentation::Centered) {
        auto *label = WrappingText(text);
        if (style == TextStyle::Secondary) Theme::SecondaryText(label);
        section_->Add(label, 0, wxEXPAND | wxALL,
            Theme::Spacing(this, Theme::Space::SectionContent));
        return;
    }
    auto *label = new wxStaticText(this, wxID_ANY, text, wxDefaultPosition, wxDefaultSize,
        presentation_ == Presentation::Centered ? wxALIGN_CENTER_HORIZONTAL : wxALIGN_LEFT);
    if (style == TextStyle::Secondary) Theme::SecondaryText(label);
    label->Wrap(presentation_ == Presentation::Centered ? GetCharWidth() * 36 : FromDIP(480));
    if (presentation_ == Presentation::Centered) {
        layout_->Add(label, 0, wxEXPAND | wxLEFT | wxRIGHT, Theme::Spacing(this, Theme::Space::Columns));
        layout_->AddSpacer(Theme::Spacing(this, Theme::Space::SectionContent));
    } else {
        layout_->Add(label, 0, wxEXPAND | wxLEFT | wxRIGHT | wxBOTTOM, Theme::Spacing(this));
    }
}
void ThemeDetailView::Logo() {
    list_ = nullptr;
    const auto icon = Theme::AppIcon(this, 64);
    if (icon.IsOk()) layout_->Add(new wxStaticBitmap(this, wxID_ANY, wxBitmap(icon)),
        0, wxALIGN_CENTER | wxALL, Theme::Spacing(this));
}
}
