// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../observables/DiagnosticsObservable.h"
#include "../theme/ThemeLongContent.h"

namespace Passepartout {
class RuntimeLogView final : public ThemeLongContent {
public:
    RuntimeLogView(wxWindow *parent, DiagnosticsObservable &diagnostics, bool tunnel);
private:
    void UpdateContent();
    DiagnosticsObservable &diagnostics_;
    bool tunnel_;
    wxTimer timer_;
};
}
