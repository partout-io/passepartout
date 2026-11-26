// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../models/InteractiveLogin.h"
#include <optional>
#include <partout/models/TaggedProfile.h>
#include <filesystem>
#include "AppPreferences.h"
#include "AppProfileHeader.h"
#include "AppConstants_github.h"
#include "ChangelogEntry.h"
#include "ConfigBundleConfig.h"
#include "ConfigFlag.h"
#include <map>
#include "Issue.h"
#include "AppTunnelInfo.h"
#include "../../../models/Credits.h"
#include <partout/models/TunnelSnapshot.h>
#include <string>

namespace Passepartout {
using ConfigBundle = std::map<Models::ConfigFlag::eConfigFlag, Models::ConfigBundleConfig>;
using ConfigFlags = std::map<Models::ConfigFlag::eConfigFlag, Partout::Json>;
using Profile = Partout::Models::TaggedProfile;
using Status = Models::AppProfileStatus::eAppProfileStatus;

namespace Profiles {
Models::AppProfileHeader Header(const Profile &profile);
inline constexpr const char LastUpdateKey[] = "lastUpdate";
inline constexpr const char FingerprintKey[] = "fingerprint";
constexpr std::size_t MaxConfigurationBytes = 1024 * 1024;
bool IsSafeId(const std::string &id);
void ValidateIdentity(const Profile &profile);
std::string ConfigurationName(const std::filesystem::path &path);
std::string ReadConfiguration(const std::filesystem::path &path);
void Sort(std::vector<Profile> &profiles);
std::optional<Passepartout::InteractiveLogin> InteractiveLoginFor(const Profile &profile);
}

namespace Preferences {
Models::AppPreferences Defaults();
Models::AppPreferences FromJson(const Partout::Json &data);
}

namespace Credits {
void Filter(Models::Credits &credits, Models::Platform::ePlatform platform);
}

namespace Tunnels {
std::vector<Models::AppTunnelInfo> Info(const std::vector<Partout::Models::TunnelSnapshot> &snapshots);
}
}

namespace Passepartout::Paths {
std::filesystem::path FromUtf8(const std::string &value);
}

namespace Passepartout::AtomicFile {
void Write(const std::filesystem::path &path, const std::string &content);
}

namespace Passepartout::Imports {
Profile DecodeResult(const char *json);
}

namespace Passepartout::Issues {
std::string Subject(const Models::Issue &issue);
std::string Body(const Models::Issue &issue, const std::string &text);
}

namespace Passepartout::Constants {
std::string IssueURL(const Models::AppConstants_github &github, int32_t issue);
std::string ChangelogURL(const Models::AppConstants_github &github, const std::string &build);
}

namespace Passepartout::Changelogs {
std::vector<Models::ChangelogEntry> Parse(const std::string &text);
}
