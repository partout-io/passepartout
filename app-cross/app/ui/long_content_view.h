// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>

namespace Passepartout {
class LongContentView final : public wxPanel {
public:
    LongContentView(wxWindow *parent, const wxString &title, const wxString &content);
};
}
