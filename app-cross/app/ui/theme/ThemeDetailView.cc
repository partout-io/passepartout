// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ThemeDetailView.h"
#include "ThemeContentLink.h"
#include "../../strings/Strings.h"
#include <wx/statbox.h>
#include "ThemeButtonRow.h"

namespace Passepartout {
ThemeDetailView::ThemeDetailView(wxWindow *parent, Presentation presentation)
    : wxScrolledWindow(parent, wxID_ANY), layout_(new wxBoxSizer(wxVERTICAL)),
      presentation_(presentation), content_parent_(this), section_(layout_) {
    Theme::Apply(this);
    SetScrollRate(0, presentation_ == Presentation::Centered ? 0 : Theme::Spacing(this));
    SetSizer(layout_);
    Bind(wxEVT_SIZE, [this](wxSizeEvent &event) {
        if (!wrap_pending_) {
            wrap_pending_ = true;
            CallAfter([this] {
                wrap_pending_ = false;
                Rewrap();
            });
        }
        event.Skip();
    });
}

void ThemeDetailView::Section(const wxString &title) {
    button_groups_.emplace_back();
    if (presentation_ != Presentation::Centered) {
        auto *box = new wxStaticBoxSizer(wxVERTICAL, this, title);
        layout_->Add(box, 0, wxEXPAND | wxLEFT | wxRIGHT | wxTOP, Theme::Spacing(this));
        content_parent_ = box->GetStaticBox();
        section_ = new wxBoxSizer(wxVERTICAL);
        box->Add(section_, 0, wxEXPAND | wxALL, Theme::Spacing(this));
        form_rows_ = nullptr;
        return;
    }
    auto *label = new wxStaticText(this, wxID_ANY, title);
    label->SetFont(label->GetFont().Bold().Scaled(1.3f));
    layout_->Add(label, 0, wxALIGN_CENTER_HORIZONTAL | wxALL,
        Theme::Spacing(this, Theme::Space::SectionContent));
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
    if (value.empty()) return;
    auto *rows = FormRows();
    rows->Add(new wxStaticText(content_parent_, wxID_ANY, title), 0, wxALIGN_CENTER_VERTICAL);
    rows->Add(Value(value, monospace), 1, wxEXPAND | wxALIGN_CENTER_VERTICAL);
}

void ThemeDetailView::CopiableField(const wxString &title, const wxString &value, bool monospace) {
    auto *text = TextField(title, value, wxTE_READONLY | wxTE_RIGHT);
    if (monospace) Theme::Monospace(text);
}

void ThemeDetailView::ContentLink(const wxString &title, std::function<void()> action,
    const wxString &value, bool enabled) {
    if (IsForm()) {
        auto *rows = FormRows();
        rows->Add(new wxStaticText(content_parent_, wxID_ANY, title), 0, wxALIGN_CENTER_VERTICAL);
        const auto label = value.empty() ? Localized(StringKey::GlobalActionsEdit) : value;
        auto *link = new ThemeContentLink(content_parent_, label, std::move(action));
        link->SetName(title);
        link->Enable(enabled);
        rows->Add(link, 0, wxALIGN_RIGHT | wxALIGN_CENTER_VERTICAL);
        return;
    }
    auto *row = new wxBoxSizer(wxHORIZONTAL);
    auto *link = new ThemeContentLink(content_parent_, title, std::move(action));
    link->Enable(enabled);
    row->Add(link, 0, wxALIGN_CENTER_VERTICAL);
    if (!value.empty()) {
        row->Add(new wxStaticText(content_parent_, wxID_ANY, value, wxDefaultPosition, wxDefaultSize, wxALIGN_RIGHT), 1,
            wxALIGN_CENTER_VERTICAL | wxLEFT, Theme::Spacing(this));
    }
    if (presentation_ == Presentation::Plain) {
        section_->Add(row, SectionRowFlags());
    } else {
        layout_->Add(row, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, Theme::Spacing(this, Theme::Space::SectionContent));
    }
}

void ThemeDetailView::ExternalLink(const wxString &title, std::function<void()> action) {
    auto *link = new ThemeContentLink(content_parent_, title, std::move(action));
    section_->Add(link, SectionRowFlags(false));
}

void ThemeDetailView::LongContent(const wxString &title, const wxString &preview,
    std::function<void()> action, bool secure) {
    ContentLink(title, std::move(action), secure ? wxString() : preview.BeforeFirst('\n'));
}

wxSizerFlags ThemeDetailView::SectionRowFlags(bool expand) {
    auto result = wxSizerFlags();
    if (expand) result.Expand();
    if (section_ == layout_) return result.Border(wxALL, Theme::Spacing(this));
    if (!section_->GetChildren().empty()) section_->AddSpacer(Theme::Spacing(this, Theme::Space::Row));
    return result;
}

wxFlexGridSizer *ThemeDetailView::FormRows() {
    if (!form_rows_) {
        form_rows_ = new wxFlexGridSizer(2, Theme::Spacing(this, Theme::Space::Row), Theme::Spacing(this, Theme::Space::Columns));
        form_rows_->AddGrowableCol(1);
        section_->Add(form_rows_, SectionRowFlags());
    }
    return form_rows_;
}

wxStaticText *ThemeDetailView::Value(const wxString &value, bool monospace) {
    auto *text = new wxStaticText(content_parent_, wxID_ANY, value.BeforeFirst('\n'),
        wxDefaultPosition, wxDefaultSize, wxST_ELLIPSIZE_END | wxALIGN_RIGHT);
    if (monospace) Theme::Monospace(text);
    text->SetMinSize(wxSize(GetCharWidth() * 12, text->GetBestSize().y));
    text->SetName(value);
    return text;
}

void ThemeDetailView::Items(const wxString &title, const std::vector<wxString> &values) {
    for (const auto &value : values) CopiableField(title, value);
}

void ThemeDetailView::EndSection() {
    button_groups_.emplace_back();
    content_parent_ = this;
    section_ = layout_;
    form_rows_ = nullptr;
}

wxButton *ThemeDetailView::ButtonRow(const wxString &title, std::function<void()> action,
    const wxString &explanation) {
    auto *row = new ThemeButtonRow(content_parent_, title, std::move(action), explanation);
    button_groups_.back().push_back(row->Button());
    ThemeButtonRow::AlignButtons(button_groups_.back());
    if (row->Explanation()) wrapped_.push_back({row->Explanation(), explanation});
    section_->Add(row, SectionRowFlags());
    form_rows_ = nullptr;
    return row->Button();
}

wxTextCtrl *ThemeDetailView::TextField(const wxString &title, const wxString &value, long style) {
    if (style & wxTE_MULTILINE) {
        auto *field = new wxBoxSizer(wxVERTICAL);
        if (!title.empty()) {
            field->Add(WrappingText(title), 0, wxEXPAND | wxBOTTOM,
                Theme::Spacing(this, Theme::Space::SectionContent));
        }
        auto *text = new wxTextCtrl(content_parent_, wxID_ANY, value,
            wxDefaultPosition, wxDefaultSize, style);
        text->SetName(title);
        text->SetMinSize(wxSize(GetCharWidth() * 40, GetCharHeight() * 8));
        field->Add(text, 1, wxEXPAND);
        section_->Add(field, SectionRowFlags().Proportion(1));
        form_rows_ = nullptr;
        return text;
    }
    if (title.empty()) {
        auto *text = new wxTextCtrl(content_parent_, wxID_ANY, value, wxDefaultPosition, wxDefaultSize, style);
        text->SetName(value);
        section_->Add(text, SectionRowFlags());
        form_rows_ = nullptr;
        return text;
    }
    auto *rows = FormRows();
    rows->Add(new wxStaticText(content_parent_, wxID_ANY, title), 0, wxALIGN_CENTER_VERTICAL);
    auto *text = new wxTextCtrl(content_parent_, wxID_ANY, value, wxDefaultPosition, wxDefaultSize, style);
    text->SetName(title);
    rows->Add(text, 1, wxEXPAND | wxALIGN_CENTER_VERTICAL);
    return text;
}

wxStaticText *ThemeDetailView::WrappingText(const wxString &text) {
    auto *label = new wxStaticText(content_parent_, wxID_ANY, text,
        wxDefaultPosition, wxDefaultSize, wxST_NO_AUTORESIZE);
    label->SetMinSize(wxSize(1, label->GetBestSize().y));
    wrapped_.push_back({label, text});
    return label;
}

void ThemeDetailView::Rewrap() {
    for (const auto &buttons : button_groups_) ThemeButtonRow::AlignButtons(buttons);
    Layout();
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
    if (presentation_ == Presentation::Centered) {
        SetMinClientSize(layout_->GetMinSize());
        SetClientSize(layout_->GetMinSize());
    }
    Layout();
    if (presentation_ != Presentation::Centered) FitInside();
}

wxCheckBox *ThemeDetailView::Toggle(const wxString &title, const wxString &support, bool checked) {
    auto *row = new wxBoxSizer(wxHORIZONTAL);
    auto *captions = new wxBoxSizer(wxVERTICAL);
    captions->Add(WrappingText(title), 0, wxEXPAND);
    wxStaticText *subtitle = nullptr;
    if (!support.empty()) {
        subtitle = WrappingText(support);
        Theme::SecondaryText(subtitle);
        captions->Add(subtitle, 0, wxEXPAND | wxTOP,
            Theme::Spacing(this, Theme::Space::SectionContent));
    }
    row->Add(captions, 1, wxALIGN_CENTER_VERTICAL | wxRIGHT, Theme::Spacing(this, Theme::Space::Columns));
    auto *control = new wxCheckBox(content_parent_, wxID_ANY, {});
    control->SetName(title);
    control->SetValue(checked);
    if (subtitle) toggle_support_[control] = subtitle;
    row->Add(control, 0, wxALIGN_CENTER_VERTICAL);
    section_->Add(row, SectionRowFlags());
    return control;
}

void ThemeDetailView::SetToggleSupport(wxCheckBox *toggle, const wxString &support) {
    const auto found = toggle_support_.find(toggle);
    if (found == toggle_support_.end()) return;
    for (auto &entry : wrapped_) {
        if (entry.label != found->second || entry.text == support) continue;
        entry.text = support;
        entry.width = -1;
        entry.label->SetLabel(support);
        Rewrap();
        return;
    }
}

wxCheckBox *ThemeDetailView::CopiableToggle(const wxString &value, bool checked) {
    auto *row = new wxBoxSizer(wxHORIZONTAL);
    auto *text = new wxTextCtrl(content_parent_, wxID_ANY, value, wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY);
    text->SetName(value);
    row->Add(text, 1, wxALIGN_CENTER_VERTICAL | wxRIGHT, Theme::Spacing(this, Theme::Space::Columns));
    auto *control = new wxCheckBox(content_parent_, wxID_ANY, {});
    control->SetName(value);
    control->SetValue(checked);
    row->Add(control, 0, wxALIGN_CENTER_VERTICAL);
    section_->Add(row, SectionRowFlags());
    return control;
}

void ThemeDetailView::Message(const wxString &text, TextStyle style) {
    if (presentation_ != Presentation::Centered) {
        auto *label = WrappingText(text);
        if (style == TextStyle::Secondary) Theme::SecondaryText(label);
        section_->Add(label, SectionRowFlags());
        return;
    }
    auto *label = new wxStaticText(this, wxID_ANY, text, wxDefaultPosition, wxDefaultSize, wxALIGN_CENTER_HORIZONTAL);
    if (style == TextStyle::Secondary) Theme::SecondaryText(label);
    label->Wrap(GetCharWidth() * 36);
    layout_->Add(label, 0, wxEXPAND | wxLEFT | wxRIGHT, Theme::Spacing(this, Theme::Space::Columns));
    layout_->AddSpacer(Theme::Spacing(this, Theme::Space::SectionContent));
}

void ThemeDetailView::Logo() {
    const auto icon = Theme::AppIcon(this, 64);
    if (icon.IsOk()) layout_->Add(new wxStaticBitmap(this, wxID_ANY, wxBitmap(icon)),
        0, wxALIGN_CENTER | wxALL, Theme::Spacing(this));
}
}
