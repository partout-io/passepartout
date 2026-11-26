// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../extensions/StateObserver.h"
#include "../../observables/CreditsObservable.h"
#include "../theme/ThemeLongContent.h"

namespace Passepartout {
class LicenseView final : public ThemeLongContent {
public:
    LicenseView(wxWindow *parent, CreditsObservable &credits, std::string url, const wxString &title);
private:
    void UpdateContent();
    CreditsObservable &credits_;
    std::string url_;
    StateObserver observer_;
};
}
