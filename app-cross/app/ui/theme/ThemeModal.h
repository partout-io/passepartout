// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Theme.h"
#include <functional>

namespace Passepartout {
class ThemeModal final : public wxDialog {
public:
    enum class Mode { ReadOnly, Editable };
    enum class Sizing { Reading, Content, FixedContent, TextInput };
    ThemeModal(wxWindow *parent, const wxString &title,
        const std::function<wxWindow *(wxWindow *)> &makeContent, Mode mode = Mode::ReadOnly, Sizing sizing = Sizing::Reading,
        std::function<bool()> canAccept = {});
};
}
