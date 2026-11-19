// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "IssueReportView.h"
#include "../../strings/Strings.h"

namespace Passepartout {
IssueReportView::IssueReportView(wxWindow *parent) : ThemeDetailView(parent) {
    comment_ = TextField(Localized(StringKey::GlobalNounsComment), {}, wxTE_MULTILINE);
    comment_->SetMaxLength(16000);
    comment_->SetFocus();
    Finish();
}
std::string IssueReportView::Comment() const {
    return comment_->GetValue().ToStdString(wxConvUTF8);
}
bool IssueReportView::CanSubmit() const {
    return !comment_->GetValue().empty();
}
}
