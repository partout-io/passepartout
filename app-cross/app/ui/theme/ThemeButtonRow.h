// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Theme.h"
#include <functional>

namespace Passepartout {
class ThemeButtonRow final : public wxBoxSizer {
public:
    ThemeButtonRow(wxWindow *parent, const wxString &title, std::function<void()> action,
                   const wxString &explanation = {});
    wxButton *Button() const { return button_; }
    wxStaticText *Explanation() const { return explanation_; }
private:
    wxButton *button_;
    wxStaticText *explanation_ = nullptr;
};
}
