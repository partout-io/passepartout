// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/detail_view.h"
#include "../../observables/diagnostics_observable.h"

namespace Passepartout {
class IssueReportView final : public ThemeDetailView {
public:
    IssueReportView(wxWindow *parent, DiagnosticsObservable &diagnostics);
};
}
