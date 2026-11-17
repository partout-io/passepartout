// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/detail_view.h"
#include "../../observables/version_observable.h"
#include "navigation.h"

namespace Passepartout {
class VersionView final : public ThemeDetailView {
public:
    VersionView(wxWindow *parent, VersionObservable &version, const wxString &name, SettingsNavigation navigate);
};
}
