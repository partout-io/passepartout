// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../observables/ProfileObservable.h"
#include "../observables/TunnelObservable.h"
#include "LoadAppConstants.h"
#include "CrossConstants.h"
#include "../business/strategy/WireGuardKeyGenerator.h"
#include "../observables/UserPreferencesObservable.h"
#include "../observables/ConfigObservable.h"
#include "../observables/VersionObservable.h"
#include "../observables/CreditsObservable.h"
#include "../observables/DiagnosticsObservable.h"

namespace Passepartout {
class AppLogger;
class AppSession;
class AppContext {
public:
    const Models::AppConstants constants;
    const CrossConstants crossConstants;
    const std::string applicationVersion;
    const std::unique_ptr<WireGuardKeyGenerator> wireGuardKeys;
private:
    std::shared_ptr<AppLogger> logger_;
    std::unique_ptr<AppSession> session_;
public:
    AppContext(const std::filesystem::path &dataRoot, bool demo,
               Models::AppConstants constants = Constants::Load(),
               CrossConstants crossConstants = defaultCrossConstants);
    ~AppContext();
    ProfileObservable profiles;
    TunnelObservable tunnel;
    UserPreferencesObservable preferences;
    ConfigObservable config;
    VersionObservable version;
    CreditsObservable credits;
    DiagnosticsObservable diagnostics;
};
}
