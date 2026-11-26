// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ChangelogView.h"
#include "../platform/Presentation.h"
#include "../../strings/Strings.h"

namespace Passepartout {
ChangelogView::ChangelogView(wxWindow *parent, VersionObservable &version)
    : wxPanel(parent), version_(version), timer_(this) {
    SetSizer(new wxBoxSizer(wxVERTICAL));
    version_.LoadChangelog();
    Bind(wxEVT_TIMER, [this](wxTimerEvent &) {
        if (!version_.Snapshot().changelog.loading) UpdateContent();
    });
    timer_.Start(100);
    UpdateContent();
}

void ChangelogView::UpdateContent() {
    const auto state = version_.Snapshot();
    Freeze();
    if (content_) {
        GetSizer()->Detach(content_);
        content_->Destroy();
    }
    content_ = new ThemeDetailView(this, ThemeDetailView::Presentation::Plain);
    GetSizer()->Add(content_, 1, wxEXPAND);
    if (state.changelog.loading) {
        content_->Message(Localized(StringKey::GlobalNounsLoading));
    } else if (state.changelog.entries.empty()) {
        content_->Message(Localized(StringKey::GlobalNounsNoContent));
    } else {
        content_->Section(wxString::FromUTF8(state.current));
        for (const auto &entry : state.changelog.entries) {
            const auto comment = wxString::FromUTF8(entry.comment);
            if (const auto url = version_.IssueURL(entry)) {
                content_->ExternalLink(comment, [this, url = *url] {
                    OpenURL(this, url);
                });
            } else {
                content_->Message(comment);
            }
        }
    }
    content_->Finish();
    Layout();
    Thaw();
    if (!state.changelog.loading) timer_.Stop();
}
}
