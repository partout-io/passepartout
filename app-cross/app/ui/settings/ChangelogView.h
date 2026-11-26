// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../extensions/StateObserver.h"
#include "../../observables/VersionObservable.h"
#include "../theme/ThemeDetailView.h"
#include "../../context/CrossConstants.h"
#include "AppConstants_github.h"

namespace Passepartout {
class ChangelogView final : public wxPanel {
public:
    ChangelogView(wxWindow *parent, VersionObservable &version, const CrossConstantsType::App &app,
                  Models::AppConstants_github github
    );
private:
    void UpdateContent();
    VersionObservable &version_;
    const std::string current_version_;
    const Models::AppConstants_github github_;
    ThemeDetailView *content_ = nullptr;
    StateObserver observer_;
};
}
