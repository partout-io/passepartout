// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../observables/session.h"

namespace Passepartout {
class AppContext {
private:
    std::unique_ptr<AppSession> session_;
public:
    AppContext(const std::filesystem::path &directory, bool demo);
    ProfileObservable profiles;
    TunnelObservable tunnel;
};
}
