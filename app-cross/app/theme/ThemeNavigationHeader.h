// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>
#include <functional>

namespace Passepartout {
class ThemeNavigationHeader final : public wxPanel {
public:
    ThemeNavigationHeader(wxWindow *parent, std::function<void()> back);
    void Update(const wxString &title, bool canGoBack);
    void HandleKey(wxKeyEvent &event, const std::function<void()> &dismiss);
private:
    wxButton *back_;
    wxStaticText *title_;
    std::function<void()> backAction_;
};
}
