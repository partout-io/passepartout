// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "theme.h"
#include "detail_list.h"
#include <wx/scrolwin.h>
#include <functional>

namespace Passepartout {
class ThemeDetailView : public wxScrolledWindow {
public:
    explicit ThemeDetailView(wxWindow *parent);
    void Section(const wxString &title);
    void Field(const wxString &title, const wxString &value, bool monospace = false);
    void Navigate(const wxString &title, std::function<void()> action,
                  const wxString &value = {}, bool enabled = true);
    wxButton *Action(const wxString &title, std::function<void()> action);
    wxTextCtrl *TextField(const wxString &title, const wxString &value, long style = 0);
    wxCheckBox *Toggle(const wxString &title, const wxString &support, bool checked);
    void Message(const wxString &text);
    void Logo();
    void Finish();
private:
    wxBoxSizer *Row(const wxString &title);
    ThemeDetailList *List(bool monospace = false);
    wxBoxSizer *layout_;
    ThemeDetailList *list_ = nullptr;
    bool monospace_ = false;
};
}
