// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ObservableFixture.h"

namespace Passepartout::Tests {
ObservableFixture::ObservableFixture(std::unique_ptr<ProfileRepository> repository, ProfileImporter importer,
                                     std::unique_ptr<Partout::Tunnel> backend, std::shared_ptr<AppLogger> logger,
                                     std::function<void(const Models::AppPreferences &)> apply_preferences
) : profiles(executor, std::make_unique<ProfileManager>(std::move(repository), std::move(importer)), logger),
    tunnel(executor, std::move(backend), std::move(logger), std::move(apply_preferences)) {
    profiles.OnChange([this](std::vector<Profile> values, bool loaded) {
        tunnel.SetProfiles(std::move(values), loaded);
    });
    profiles.Load();
}

ObservableFixture::~ObservableFixture() {
    executor.RequestStop();
    profiles.Cancel();
    tunnel.Cancel();
    executor.Join();
}

void ObservableFixture::ClearError() {
    profiles.ClearError();
    tunnel.ClearError();
}
}
