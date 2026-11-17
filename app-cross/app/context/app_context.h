// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../observables/profile_observable.h"
#include "../observables/tunnel_observable.h"
#include "dependencies.h"
#include "../business/wireguard_key_generator.h"
#include "../observables/user_preferences_observable.h"
#include "../observables/config_observable.h"
#include "../observables/version_observable.h"
#include "../observables/credits_observable.h"
#include "../observables/diagnostics_observable.h"

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
               Models::AppConstants constants = LoadAppConstants(),
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
