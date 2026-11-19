// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include "../../observables/CreditsObservable.h"
#include "SettingsPresentation.h"

namespace Passepartout {
class CreditsView final : public ThemeDetailView {
public:
    CreditsView(wxWindow *parent, CreditsObservable &credits, SettingsPresentation present);
};
}
