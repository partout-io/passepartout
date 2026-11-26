// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ObservableFixture.h"

namespace Passepartout::Tests {
ObservableFixture::ObservableFixture(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
                                     std::unique_ptr<Partout::Tunnel> backend
) : profile_manager(std::move(repository), std::move(importer)),
    profiles(executor, profile_manager),
    tunnel(executor, std::move(backend), profile_manager) {
    tunnel.Refresh();
    profiles.Load();
}

ObservableFixture::~ObservableFixture() {
    executor.RequestStop();
    profiles.Cancel();
    tunnel.Cancel();
    executor.Join();
}

void ObservableFixture::ClearOperationErrors() {
    profiles.ClearOperationError();
    tunnel.ClearOperationError();
}
}
