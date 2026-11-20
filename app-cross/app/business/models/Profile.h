// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <partout/models/TaggedProfile.h>
#include <filesystem>

namespace Passepartout {
using Profile = Partout::Models::TaggedProfile;
constexpr std::size_t MaxConfigurationBytes = 1024 * 1024;
bool IsSafeProfileId(const std::string &id);
void ValidateProfileIdentity(const Profile &profile);
std::string ReadConfiguration(const std::filesystem::path &path);
void SortProfiles(std::vector<Profile> &profiles);
}
