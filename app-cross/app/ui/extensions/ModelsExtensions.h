// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <cstdint>
#include <string>
#include <functional>
#include "ProfileTransfer.h"
#include <filesystem>
#include <partout/models/TaggedModule.h>
#include "../platform/ConfigurationPicker.h"
#include "../../business/models/ConfigurationFiles.h"

class wxString;
class wxWindow;

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

namespace Passepartout::Configuration {
using PickerFactory = std::function<std::unique_ptr<ConfigurationPicker>(wxWindow &)>;
std::unique_ptr<ConfigurationPicker> MakePicker(wxWindow &owner);

// Keep failures from individual native file reads separate from batch failures.
template<typename Stage>
ConfigurationFiles CollectFiles(std::size_t count, Stage stage) {
    std::vector<std::filesystem::path> paths;
    std::size_t failures = 0;
    for (std::size_t index = 0; index < count; ++index) {
        try {
            paths.push_back(stage(index));
        } catch (...) {
            ++failures;
        }
    }
    return ConfigurationFiles(std::move(paths), failures);
}
}
