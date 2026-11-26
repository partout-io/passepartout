// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <partout/models/TaggedProfile.h>
#include <filesystem>
#include "AppPreferences.h"
#include "ConfigBundleConfig.h"
#include "ConfigFlag.h"
#include <map>
#include "Issue.h"
#include "AppTunnelInfo.h"
#include "../../../models/Credits.h"
#include <partout/models/TunnelSnapshot.h>
#include <string>
#include <partout/models/ABIEnvelope.h>
#include <stdexcept>

namespace Passepartout {
using ConfigBundle = std::map<Models::ConfigFlag::eConfigFlag, Models::ConfigBundleConfig>;
using ConfigFlags = std::map<Models::ConfigFlag::eConfigFlag, Partout::Json>;
using Profile = Partout::Models::TaggedProfile;
using Status = Models::AppProfileStatus::eAppProfileStatus;

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
inline Profile DecodeResult(const char *json) {
    if (!json) throw std::runtime_error("Partout could not import this configuration.");
    try {
        const auto envelope = Partout::Models::ABIEnvelope::FromJson(Partout::Json::Parse(json));
        if (envelope.code || !envelope.payload)
            throw std::runtime_error("Import failed");
        return Profile::FromJson(*envelope.payload);
    } catch (...) {
        // ABI errors and parser details may contain configuration secrets.
        throw std::runtime_error("Partout could not import this configuration.");
    }
}
}

namespace Passepartout::Issues {
std::string Subject(const Models::Issue &issue);
std::string Body(const Models::Issue &issue, const std::string &text);
}
