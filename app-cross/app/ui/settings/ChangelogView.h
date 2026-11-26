// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../observables/VersionObservable.h"
#include "../theme/ThemeDetailView.h"

namespace Passepartout {
class ChangelogView final : public wxPanel {
public:
    ChangelogView(wxWindow *parent, VersionObservable &version);
private:
    void UpdateContent();
    VersionObservable &version_;
    wxTimer timer_;
    ThemeDetailView *content_ = nullptr;
};
}
