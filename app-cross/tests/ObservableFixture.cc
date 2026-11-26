// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ObservableFixture.h"

namespace Passepartout::Tests {
ObservableFixture::ObservableFixture(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
                                     std::unique_ptr<Partout::Tunnel> backend
) : profiles(executor, std::make_unique<ProfileManager>(std::move(repository), std::move(importer))),
    tunnel(executor, std::move(backend)) {
    tunnel.Refresh();
    profiles.OnRemove([this](const std::string &id) {
        tunnel.Remove(id);
    });
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
