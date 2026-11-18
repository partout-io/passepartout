// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../observables/DiagnosticsObservable.h"
#include <wx/wx.h>

namespace Passepartout {
class RuntimeLogView final : public wxPanel {
public:
    RuntimeLogView(wxWindow *parent, DiagnosticsObservable &diagnostics, bool tunnel);
private:
    void UpdateContent();
    DiagnosticsObservable &diagnostics_;
    bool tunnel_;
    wxTextCtrl *content_;
    wxTimer timer_;
};
}
