// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ChangelogView.h"
#include "../../business/extensions/AppConstantsExtensions.h"
#include "../platform/Presentation.h"
#include "../../strings/Strings.h"

namespace Passepartout {
ChangelogView::ChangelogView(wxWindow *parent, VersionObservable &version, const CrossConstantsType::App &app,
                             Models::AppConstants_github github
)
    : wxPanel(parent), version_(version), current_version_(app.version_number),
      github_(std::move(github)), observer_([this] { UpdateContent(); }) {
    SetSizer(new wxBoxSizer(wxVERTICAL));
    version_.LoadChangelog(std::to_string(app.build_number));
    observer_.Observe(version_.changes);
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
        content_->Section(wxString::FromUTF8(current_version_));
        for (const auto &entry : state.changelog.entries) {
            const auto comment = wxString::FromUTF8(entry.comment);
            if (entry.issue) {
                const auto url = Constants::IssueURL(github_, *entry.issue);
                content_->ExternalLink(comment, [this, url] {
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
}
}
