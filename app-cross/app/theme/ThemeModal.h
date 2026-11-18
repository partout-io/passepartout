// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Theme.h"
#include <functional>

namespace Passepartout {
class ThemeModal final : public wxDialog {
public:
    ThemeModal(wxWindow *parent, const wxString &title,
        const std::function<wxWindow *(wxWindow *)> &makeContent);
};
}
