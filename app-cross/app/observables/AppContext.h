// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ProfileObservable.h"
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
class AppContext final {
public:
    const Models::AppConstants constants;
    const CrossConstantsType cross_constants;
    const std::string application_version;
    const std::unique_ptr<WireGuardKeyGenerator> wire_guard_keys;
private:
    SerialExecutor executor_;
public:
    AppContext(const std::filesystem::path &data_root, bool demo,
               Models::AppConstants constants = Constants::Load(),
               CrossConstantsType cross_constants = CrossConstants
    );
    ~AppContext();
    SerialExecutor::Activity Activity() const;
    ProfileObservable profiles;
    TunnelObservable tunnel;
    UserPreferencesObservable preferences;
    ConfigObservable config;
    VersionObservable version;
    CreditsObservable credits;
    DiagnosticsObservable diagnostics;
};
}
