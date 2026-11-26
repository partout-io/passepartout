// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../business/strategy/ConfigurationFiles.h"
#include "../../observables/TunnelObservable.h"
#include <cstdint>
#include <string>
#include <functional>
#include "ProfileTransfer.h"
#include <filesystem>
#include <partout/models/TaggedModule.h>

class wxString;

namespace Passepartout::DataUnits {
using NumberFormatter = std::function<std::string(double, int)>;
std::string Format(int64_t bytes, NumberFormatter formatter = {});
}

namespace Passepartout::Profiles {
std::string TransferText(const Models::ProfileTransfer &transfer, DataUnits::NumberFormatter formatter = {});
}

namespace Passepartout::Paths {
std::filesystem::path FromString(const wxString &value);
}

namespace Passepartout::Modules {
wxString Title(const Partout::Models::TaggedModule &module);
}

namespace Passepartout {
// Keep failures from individual native file reads separate from batch failures.
template<typename Stage>
FileConfigurationFiles CollectConfigurationFiles(std::size_t count, Stage stage) {
    std::vector<std::filesystem::path> paths;
    std::size_t failures = 0;
    for (std::size_t index = 0; index < count; ++index) {
        try {
            paths.push_back(stage(index));
        } catch (...) {
            ++failures;
        }
    }
    return FileConfigurationFiles(std::move(paths), failures);
}
}

namespace Passepartout::Tunnels {
struct ToggleState final {
    bool is_on = false;
    bool can_interact = false;
    Status status = Status::disconnected;
};

ToggleState StateForProfile(const TunnelObservable::State &state, const std::string &id);
std::optional<InteractiveLogin> SetEnabled(TunnelObservable &tunnel, Profile profile, bool enabled);
}
