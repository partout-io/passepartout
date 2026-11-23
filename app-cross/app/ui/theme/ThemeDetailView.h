// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Theme.h"
#include <wx/scrolwin.h>
#include <functional>
#include <vector>
#include <map>

namespace Passepartout {
class ThemeDetailView : public wxScrolledWindow {
public:
    enum class Presentation { Form, Plain, Centered };
    explicit ThemeDetailView(wxWindow *parent, Presentation presentation = Presentation::Plain);
    void Section(const wxString &title);
    void EndSection();
    void Field(const wxString &title, const wxString &value, bool monospace = false);
    void CopiableField(const wxString &title, const wxString &value, bool monospace = false);
    void ContentLink(const wxString &title, std::function<void()> action,
                  const wxString &value = {}, bool enabled = true);
    void ExternalLink(const wxString &title, std::function<void()> action);
    void LongContent(const wxString &title, const wxString &preview, std::function<void()> action, bool secure = false);
    void Items(const wxString &title, const std::vector<wxString> &values);
    wxButton *ButtonRow(const wxString &title, std::function<void()> action,
                        const wxString &explanation = {});
    wxTextCtrl *TextField(const wxString &title, const wxString &value, long style = 0);
    wxCheckBox *Toggle(const wxString &title, const wxString &support, bool checked);
    void SetToggleSupport(wxCheckBox *toggle, const wxString &support);
    wxCheckBox *CopiableToggle(const wxString &value, bool checked);
    enum class TextStyle { Primary, Secondary };
    void Message(const wxString &text, TextStyle style = TextStyle::Primary);
    void Logo();
    void Finish();
protected:
    bool IsForm() const { return presentation_ == Presentation::Form; }
private:
    wxStaticText *WrappingText(const wxString &text);
    void Rewrap();
    struct WrappedLabel {
        wxStaticText *label;
        wxString text;
        int width = -1;
    };
    std::vector<WrappedLabel> wrapped_;
    std::map<wxCheckBox *, wxStaticText *> toggle_support_;
    std::vector<std::vector<wxButton *>> button_groups_{1};
    bool wrap_pending_ = false;
    wxSizerFlags SectionRowFlags(bool expand = true);
    wxFlexGridSizer *FormRows();
    wxStaticText *Value(const wxString &value, bool monospace = false);
    wxBoxSizer *layout_;
    Presentation presentation_;
    wxWindow *content_parent_;
    wxSizer *section_;
    wxFlexGridSizer *form_rows_ = nullptr;
};
}
