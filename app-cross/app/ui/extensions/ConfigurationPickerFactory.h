// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../platform/ConfigurationPicker.h"
#include <functional>

class wxWindow;

namespace Passepartout {
using ConfigurationPickerFactory = std::function<std::unique_ptr<ConfigurationPicker>(wxWindow &)>;
std::unique_ptr<ConfigurationPicker> MakeConfigurationPicker(wxWindow &owner);
}
