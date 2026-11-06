// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../observables/session.h"
#include "dependencies.h"

namespace Passepartout {
class AppContext {
public:
    const Models::AppConstants constants;
    const CrossConstants crossConstants;
private:
    std::shared_ptr<AppLogger> logger_;
    std::unique_ptr<AppSession> session_;
public:
    AppContext(const std::filesystem::path &dataRoot, bool demo,
               Models::AppConstants constants = LoadAppConstants(),
               CrossConstants crossConstants = defaultCrossConstants);
    ProfileObservable profiles;
    TunnelObservable tunnel;
};
}
