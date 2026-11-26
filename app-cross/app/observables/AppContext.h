// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ProfileObservable.h"
#include <functional>
#include "TunnelObservable.h"
#include "../context/ContextExtensions.h"
#include "../context/CrossConstants.h"
#include "../business/strategy/WireGuardKeyGenerator.h"
#include "UserPreferencesObservable.h"
#include "ConfigObservable.h"
#include "VersionObservable.h"
#include "CreditsObservable.h"
#include "DiagnosticsObservable.h"

namespace Passepartout {
class AppLogger;
class AppSession;
class AppContext final {
public:
    const Models::AppConstants constants;
    const CrossConstantsType cross_constants;
    const std::string application_version;
    const std::unique_ptr<WireGuardKeyGenerator> wire_guard_keys;
private:
    std::shared_ptr<AppLogger> logger_;
    std::unique_ptr<AppSession> session_;
public:
    AppContext(const std::filesystem::path &data_root, bool demo,
               Models::AppConstants constants = Constants::Load(),
               CrossConstantsType cross_constants = CrossConstants,
               std::function<void(const Models::AppPreferences &)> store_preferences = {}
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
