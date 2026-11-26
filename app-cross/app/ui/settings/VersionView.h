// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include "../../observables/VersionObservable.h"
#include "SettingsPresentation.h"
#include "../../context/CrossConstants.h"
#include "AppConstants_github.h"

namespace Passepartout {
class VersionView final : public ThemeDetailView {
public:
    VersionView(wxWindow *parent, VersionObservable &version, const CrossConstantsType::App &app,
                const Models::AppConstants_github &github, SettingsPresentation present
    );
};
}
