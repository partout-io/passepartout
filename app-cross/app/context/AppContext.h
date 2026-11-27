// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../observables/ProfileObservable.h"
#include "../observables/TunnelObservable.h"
#include "ContextExtensions.h"
#include "CrossConstants.h"
#include "../business/strategy/WireGuardKeyGenerator.h"
#include "../observables/UserPreferencesObservable.h"
#include "../observables/ConfigObservable.h"
#include "../observables/VersionObservable.h"
#include "../observables/CreditsObservable.h"
#include "../observables/DiagnosticsObservable.h"

namespace Passepartout {
class AppContext final {
public:
    const Models::AppConstants constants;
    const CrossConstantsType cross_constants;
    const std::unique_ptr<WireGuardKeyGenerator> wireguard_keygen;
private:
    Worker executor_;
    ProfileManager profile_manager_;
    std::shared_ptr<PreferencesStore> preferences_store_;
public:
    AppContext(const std::filesystem::path &data_root,
               Models::AppConstants constants = Constants::Load(),
               CrossConstantsType cross_constants = CrossConstants,
               bool demo = false
    );
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
