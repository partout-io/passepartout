// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "observables/ProfileObservable.h"
#include "observables/TunnelObservable.h"

namespace Passepartout::Tests {
// Portable composition of the production observables with injected dependencies.
class ObservableFixture final {
public:
    ObservableFixture(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
                      std::unique_ptr<Partout::Tunnel> tunnel
    );
    ~ObservableFixture();
    void ClearOperationErrors();
    Worker executor;
    ProfileObservable profiles;
    TunnelObservable tunnel;
};
}
