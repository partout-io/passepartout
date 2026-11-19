// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include "../../observables/DiagnosticsObservable.h"

namespace Passepartout {
class IssueReportView final : public ThemeDetailView {
public:
    IssueReportView(wxWindow *parent, DiagnosticsObservable &diagnostics);
};
}
