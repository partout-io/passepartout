// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"

namespace Passepartout {
class IssueReportView final : public ThemeDetailView {
public:
    explicit IssueReportView(wxWindow *parent);
    std::string Comment() const;
    bool CanSubmit() const;
private:
    wxTextCtrl *comment_;
};
}
