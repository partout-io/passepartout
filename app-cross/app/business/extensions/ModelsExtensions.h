// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <partout/models/TaggedProfile.h>
#include <filesystem>
#include "AppPreferences.h"
#include "AppTunnelInfo.h"
#include "../../../models/Credits.h"
#include <partout/models/TunnelSnapshot.h>

namespace Passepartout {
using Profile = Partout::Models::TaggedProfile;

namespace Profiles {
constexpr std::size_t MaxConfigurationBytes = 1024 * 1024;
bool IsSafeId(const std::string &id);
void ValidateIdentity(const Profile &profile);
std::string ConfigurationName(const std::filesystem::path &path);
std::string ReadConfiguration(const std::filesystem::path &path);
void Sort(std::vector<Profile> &profiles);
}

namespace Preferences {
Models::AppPreferences Defaults();
}

namespace Credits {
Models::Platform::ePlatform CurrentPlatform();
void Filter(Models::Credits &credits, Models::Platform::ePlatform platform);
}

using Status = Models::AppProfileStatus::eAppProfileStatus;

namespace Tunnels {
std::vector<Models::AppTunnelInfo> Info(const std::vector<Partout::Models::TunnelSnapshot> &snapshots);
}
}
