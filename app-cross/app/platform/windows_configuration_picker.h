// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../ui/configuration_picker.h"
#include <windows.h>

namespace Passepartout {
// The owner must outlive the picker. Construct and start on its UI thread.
std::unique_ptr<ConfigurationPicker> MakeWindowsConfigurationPicker(HWND owner);
}
