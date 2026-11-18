// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/ConfigurationFiles.h"
#include <optional>

namespace Passepartout {
struct ConfigurationPickerResult {
    std::shared_ptr<const ConfigurationFiles> files;
    bool failed = false;
};

// Presentation boundary. Poll and Cancel run on the UI thread; results own any
// temporary files until the asynchronous import transaction has consumed them.
class ConfigurationPicker {
public:
    virtual ~ConfigurationPicker() = default;
    virtual void Start() = 0;
    virtual std::optional<ConfigurationPickerResult> Poll() = 0;
    virtual void Cancel() = 0;
};
}
