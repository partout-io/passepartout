// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Theme.h"
#include "ThemeDetailList.h"
#include <wx/scrolwin.h>
#include <functional>
#include <vector>

namespace Passepartout {
class ThemeDetailView : public wxScrolledWindow {
public:
    enum class Presentation { List, Form };
    explicit ThemeDetailView(wxWindow *parent, Presentation presentation = Presentation::List);
    void Section(const wxString &title);
    void Field(const wxString &title, const wxString &value, bool monospace = false);
    void Navigate(const wxString &title, std::function<void()> action,
                  const wxString &value = {}, bool enabled = true);
    void LongContent(const wxString &title, const wxString &content, std::function<void()> action);
    void Items(const wxString &title, const std::vector<wxString> &values);
    void Table(const std::vector<wxString> &columns, const std::vector<std::vector<wxString>> &rows);
    wxButton *Action(const wxString &title, std::function<void()> action);
    wxTextCtrl *TextField(const wxString &title, const wxString &value, long style = 0);
    wxCheckBox *Toggle(const wxString &title, const wxString &support, bool checked);
    void Message(const wxString &text);
    void Logo();
    void Finish();
protected:
    bool IsForm() const { return presentation_ == Presentation::Form; }
private:
    wxFlexGridSizer *FormRows();
    wxStaticText *Value(const wxString &value, bool monospace = false);
    wxBoxSizer *Row(const wxString &title);
    ThemeDetailList *List();
    wxBoxSizer *layout_;
    ThemeDetailList *list_ = nullptr;
    Presentation presentation_;
    wxWindow *contentParent_;
    wxSizer *section_;
    wxFlexGridSizer *formRows_ = nullptr;
};
}
