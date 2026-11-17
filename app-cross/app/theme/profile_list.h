// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "list.h"

namespace Passepartout {
class ThemeProfileList final : public ThemeList {
public:
    explicit ThemeProfileList(wxWindow *parent);
    void AppendProfile(const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer);
    void UpdateProfile(unsigned row, const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer);
    static constexpr unsigned TransferColumn = 2;
    static constexpr unsigned ToggleColumn = 3;
};
}
